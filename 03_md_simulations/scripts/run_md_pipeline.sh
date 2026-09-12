#!/usr/bin/env bash
# =============================================================================
# run_md_pipeline.sh — GROMACS system preparation pipeline for IL-2 systems
#
# STATUS: Reconstructed from the confirmed, documented commands in
# ../modelling_scripts/README.md, ../box_solvation_ionisation/README.md,
# ../energy_minimisation/README.md, and ../equilibration/README.md.
# The literal historical shell script (if one ever existed) was not
# recoverable from shell history on the HPC — see those READMEs for the
# full account. This script reproduces the exact confirmed commands,
# parameters, and flags used, verified against each system's own
# pdb2gmx.log / editconf.log / genion.log / grompp/mdrun logs, and is
# genuinely runnable end-to-end; it is not a literal recovered artifact.
#
# USAGE:
#   ./run_md_pipeline.sh <input.pdb> <output_dir> <mode>
#
#   <mode> is one of:
#     reference   — automatic protonation/disulfide/terminus assignment
#                   (used for apo_1M47, open_1PY2, receptor_1Z92)
#     ai_seed     — interactive assignment (-his -ter -ss)
#                   (used for 13 of 16 systems; see KNOWN EXCEPTIONS below)
#
# KNOWN EXCEPTIONS not covered by the two modes above (documented in
# ../modelling_scripts/README.md — run these systems' pdb2gmx step
# manually with the flags shown there instead of via this script):
#   - MSA_Subsampling/01_fidelity_apo : missing -ff flag in the original run
#   - MSA_Subsampling/02_fidelity_ligand : used "reference" mode despite
#     being an AI seed, AND never ran genion (see box_solvation_ionisation
#     README — confirmed net-neutral without added ions; skip the genion
#     step entirely for this one system if reproducing it exactly)
#   - MSA_Subsampling/05_discordance : used only -ignh -ss (no -his -ter)
#
# Requires: GROMACS 2025.4 on PATH, AMBER99SB-ILDN force field available,
# .mdp files from ../mdp/ (referenced below via relative path).
# =============================================================================
set -euo pipefail

INPUT_PDB="$1"
OUTDIR="$2"
MODE="$3"   # reference | ai_seed
MDP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../mdp" && pwd)"

if [[ "$MODE" != "reference" && "$MODE" != "ai_seed" ]]; then
  echo "ERROR: mode must be 'reference' or 'ai_seed' (got: $MODE)" >&2
  exit 1
fi

mkdir -p "$OUTDIR"/{input,topology,box,solvation,ions,minimisation,equilibration/replica_01,production/replica_01,production/replica_02,production/replica_03,logs}
cp "$INPUT_PDB" "$OUTDIR/input/"
cd "$OUTDIR"

# --- 1. pdb2gmx: force field, water model, protonation/disulfide/terminus ---
# Confirmed settings for all 16 systems: AMBER99SB-ILDN force field, TIP3P
# water (../force_field/README.md). Protonation/disulfide/terminus handling
# differs by mode:
if [[ "$MODE" == "reference" ]]; then
  # Automatic assignment — GROMACS' own structural analysis decides
  # protonation state, terminus type, and disulfide bonding.
  # Confirmed identical result to the interactive mode below for this
  # protein (HISE at 16/55/79, Cys58-Cys105 disulfide) -- see
  # ../modelling_scripts/README.md.
  gmx pdb2gmx -f "input/$(basename "$INPUT_PDB")" -o topology/processed.gro \
    -p topology/topol.top -i topology/posre.itp \
    -ff amber99sb-ildn -water tip3p -ignh \
    > logs/pdb2gmx.log 2>&1
else
  # Interactive assignment — requires manual histidine tautomer selection
  # (HISE confirmed correct at 16/55/79 for this protein), terminus
  # confirmation, and disulfide-bond confirmation (Cys58-Cys105: y).
  # This step cannot run fully unattended; pipe or redirect stdin with
  # the appropriate answers if automating, e.g.:
  #   printf '1\n1\n1\ny\n' | gmx pdb2gmx ...
  # (1 = HISE for each of the 3 histidines, y = confirm disulfide)
  gmx pdb2gmx -f "input/$(basename "$INPUT_PDB")" -o topology/processed.gro \
    -p topology/topol.top -i topology/posre.itp \
    -ff amber99sb-ildn -water tip3p -ignh -his -ter -ss \
    > logs/pdb2gmx.log 2>&1
fi

# --- 2. editconf: dodecahedral box, 1.2 nm solute-to-edge, centred ---
# Confirmed identical across all 16 systems (../box_solvation_ionisation/README.md)
gmx editconf -f topology/processed.gro -o box/boxed.gro \
  -c -d 1.2 -bt dodecahedron \
  > logs/editconf.log 2>&1

# --- 3. solvate: spc216.gro coordinate template (NOT the water model itself --
#     TIP3P physics come from topol.top's #include tip3p.itp; spc216.gro is
#     just GROMACS' generic solvent-coordinate template -- see force_field
#     README for why this is not a mismatch) ---
gmx solvate -cp box/boxed.gro -cs spc216.gro -o solvation/solvated.gro \
  -p topology/topol.top \
  > logs/solvate.log 2>&1

# --- 4. genion: 0.15 M NaCl, charge-neutralised ---
# NOTE: MSA_Subsampling/02_fidelity_ligand skipped this step entirely in
# the original run (confirmed net-neutral without ions regardless) -- see
# KNOWN EXCEPTIONS above. Skip this block if reproducing that system.
gmx grompp -f "$MDP_DIR/ions.mdp" -c solvation/solvated.gro -p topology/topol.top \
  -o ions/ions.tpr -maxwarn 1 \
  > logs/grompp_ions.log 2>&1
echo "SOL" | gmx genion -s ions/ions.tpr -o ions/ionised.gro -p topology/topol.top \
  -pname NA -nname CL -neutral -conc 0.15 \
  > logs/genion.log 2>&1

# --- 5. Energy minimisation ---
gmx grompp -f "$MDP_DIR/minim.mdp" -c ions/ionised.gro -p topology/topol.top \
  -o minimisation/em.tpr -maxwarn 1 \
  > logs/grompp_em.log 2>&1
gmx mdrun -s minimisation/em.tpr -deffnm minimisation/em -v \
  > logs/mdrun_em_console.log 2>&1

# --- 6. NVT equilibration (100 ps, 300 K, protein position-restrained) ---
gmx grompp -f "$MDP_DIR/nvt.mdp" -c minimisation/em.gro -r minimisation/em.gro \
  -p topology/topol.top -o equilibration/replica_01/nvt.tpr -maxwarn 1 \
  > logs/grompp_nvt.log 2>&1
gmx mdrun -s equilibration/replica_01/nvt.tpr -deffnm equilibration/replica_01/nvt -v \
  > logs/mdrun_nvt_replica_01_console.log 2>&1

# --- 7. NPT equilibration (100 ps, 300 K / 1 bar, continues from NVT) ---
gmx grompp -f "$MDP_DIR/npt.mdp" -c equilibration/replica_01/nvt.gro \
  -t equilibration/replica_01/nvt.cpt -r equilibration/replica_01/nvt.gro \
  -p topology/topol.top -o equilibration/replica_01/npt.tpr -maxwarn 1 \
  > logs/grompp_npt.log 2>&1
gmx mdrun -s equilibration/replica_01/npt.tpr -deffnm equilibration/replica_01/npt -v \
  > logs/mdrun_npt_replica_01_console.log 2>&1

# --- 8. Production, replica 1: continues NPT's momentum/checkpoint directly ---
gmx grompp -f "$MDP_DIR/production.mdp" -c equilibration/replica_01/npt.gro \
  -t equilibration/replica_01/npt.cpt -p topology/topol.top \
  -o production/replica_01/production.tpr -maxwarn 1 \
  > logs/grompp_production_replica_01.log 2>&1
# Submit via SLURM (see submit_production.slurm) rather than running mdrun
# directly here -- production is GPU-accelerated and takes hours, not
# suitable for interactive/foreground execution.
echo "Replica 1 .tpr ready: production/replica_01/production.tpr"
echo "Submit with: sbatch $(dirname "${BASH_SOURCE[0]}")/submit_production.slurm production/replica_01"

# --- 9. Production, replicas 2 & 3: same starting coordinates, fresh
#     independently-randomised velocities (gen-vel=yes, gen-seed=-1 in
#     production_replicate.mdp) -- NOT continued from NPT's checkpoint ---
for rep in 02 03; do
  gmx grompp -f "$MDP_DIR/production_replicate.mdp" -c equilibration/replica_01/npt.gro \
    -p topology/topol.top -o "production/replica_$rep/production.tpr" -maxwarn 1 \
    > "logs/grompp_production_replica_$rep.log" 2>&1
  echo "Replica $rep .tpr ready: production/replica_$rep/production.tpr"
  echo "Submit with: sbatch $(dirname "${BASH_SOURCE[0]}")/submit_production.slurm production/replica_$rep"
done

echo ""
echo "System preparation complete: $OUTDIR"
echo "All .tpr files for production are ready; submit each via SLURM (see submit_production.slurm)."
