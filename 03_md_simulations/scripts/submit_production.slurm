#!/bin/bash
# =============================================================================
# submit_production.slurm — SLURM submission script for GROMACS production MD
#
# STATUS: Reconstructed verbatim from the confirmed SBATCH directives and
# mdrun invocation recorded in ../production/README.md (sourced from
# apo_1M47/production/replica_01/submit.slurm). The generic $1 argument
# (production run directory) is added here so this one script can submit
# any system/replica; the original per-system scripts on the HPC each
# hardcoded their own paths and job name instead.
#
# USAGE:
#   sbatch submit_production.slurm <path/to/production/replica_NN>
#   e.g. sbatch submit_production.slurm runs/apo_1M47/production/replica_01
#
#   The target directory must already contain production.tpr (produced by
#   run_md_pipeline.sh).
# =============================================================================
#SBATCH --job-name=il2_production
#SBATCH --partition=normalrun
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --mem=6G
#SBATCH --time=7-00:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

RUNDIR="$1"
if [[ -z "$RUNDIR" || ! -f "$RUNDIR/production.tpr" ]]; then
  echo "ERROR: usage: sbatch submit_production.slurm <path containing production.tpr>" >&2
  exit 1
fi

source /usr/local/gromacs/bin/GMXRC
cd "$RUNDIR"

gmx mdrun -s production.tpr -deffnm production -v -nb gpu -pme gpu -bonded gpu -ntmpi 1 -ntomp 8 -pin on
