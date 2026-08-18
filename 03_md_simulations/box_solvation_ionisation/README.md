# Box Definition, Solvation, Ionisation

## Confirmed settings — consistent across all 16 systems

- **Box**: dodecahedral (`-bt dodecahedron`), 1.2 nm minimum solute-to-edge
  distance (`-d 1.2`), centred (`-c`).
- **Solvation**: `gmx solvate` with the `spc216.gro` coordinate template
  (see `../force_field/README.md` for why this is not a mismatch with
  the TIP3P water model actually applied).
- **Ionisation**: `gmx genion -pname NA -nname CL -neutral -conc 0.15`
  — 0.15 M NaCl, system charge-neutralised.

## Box volumes and ion counts — full table (all 16 systems)

Box volume scales with each system's own size/shape; ion count scales
proportionally with box volume, consistent with a fixed 0.15 M target
concentration applied uniformly:

| System | Box volume (nm³) | NA ions | CL ions |
|---|---|---|---|
| `apo_1M47` (reference) | 523.76 | 47 | 47 |
| `open_1PY2` (reference) | 541.05 | 49 | 49 |
| `receptor_1Z92` (reference) | 468.92 | 42 | 42 |
| AFsample2 `01_fidelity_apo` | 388.71 | 35 | 35 |
| AFsample2 `02_fidelity_ligand` | 388.71 | 35 | 35 |
| AFsample2 `03_transition_state` | *(editconf log not located)* | 35 | 35 |
| AFsample2 `04_diversity_representative` | 395.57 | 36 | 36 |
| AFsample2 `05_discordance` | 352.50 | 32 | 32 |
| MSA Subsampling `01_fidelity_apo` | 390.43 | 35 | 35 |
| MSA Subsampling `02_fidelity_ligand` | N/A — no genion applied (system confirmed net-neutral without ions, see note) | **0 (confirmed)** | **0 (confirmed)** |
| MSA Subsampling `03_transition_state` | 366.89 | 33 | 33 |
| MSA Subsampling `04_diversity_representative` | 382.83 | 35 | 35 |
| MSA Subsampling `05_discordance` | 378.26 | 34 | 34 |
| BioEmu `01_centroid_01` | 405.78 | 37 | 37 |
| BioEmu `02_centroid_02` | 350.23 | 32 | 32 |
| BioEmu `03_centroid_03` | 449.99 | 41 | 41 |

Two logging gaps noted rather than filled in: AFsample2
`03_transition_state`'s `editconf.log` wasn't located at the expected
path (ion counts were still recoverable from its `genion.log`), and
MSA Subsampling `02_fidelity_ligand` — see the confirmed finding below,
which goes beyond a simple missing log.

## Confirmed anomaly: MSA Subsampling `02_fidelity_ligand` ran unionised

Unlike every other one of the 16 systems, `02_fidelity_ligand` was
**never ionised**. This was independently confirmed three ways, not
inferred from a missing log:

1. `topol.top`'s `[ molecules ]` section lists only `Protein_chain_A`
   and `SOL` — no `NA`/`CL` entries.
2. The system's actual simulated coordinates
   (`equilibration/replica_01/npt.gro`) contain **zero** NA and **zero**
   CL atoms (`grep -c " NA " ... ` / `grep -c " CL " ...` both return 0).
3. No `genion.log` exists for this system anywhere on disk (checked
   directly, not just at the expected path).

`ions.itp` **is** included in the topology
(`#include ".../amber99sb-ildn.ff/ions.itp"`, line 20992) — this is
automatic default behaviour from `pdb2gmx`, giving the topology access
to ion parameters, and does **not** by itself mean ions were added. The
`genion` step, which actually places NA/CL molecules into the system and
records them in `[ molecules ]`, was simply never run for this seed.

**Confirmed the protein itself is net-neutral, so this is not a
non-neutral-system issue**: the topology's cumulative `qtot` annotation
reaches exactly `qtot 0` at the final atom
(`grep "qtot" topol.top | tail -1`). This rules out the more serious
concern (an uncompensated net charge under periodic PME electrostatics)
— the protein has zero net charge with or without added ions, so no
implicit background-charge correction was needed or applied.

**Also confirmed distinct for this system**: its `pdb2gmx` command
(`gmx pdb2gmx -f .../02_fidelity_ligand.pdb -o processed.gro -p topol.top
-i posre.itp -water tip3p -ignh`) used automatic protonation/disulfide
assignment (no `-his -ter -ss`), matching the *reference-structure*
processing pattern rather than the interactive pattern used for every
other AI-seeded system — and its force field is included via a
non-standard relative path,
`../01_fidelity_apo/local_gmxlib/amber99sb-ildn.ff/`, referencing a
local copy staged inside the **sibling** `01_fidelity_apo` seed
directory rather than GROMACS' standard installation path used
everywhere else.

**Practical consequence, stated precisely**: the system is charge-neutral
(confirmed), but it was simulated in **pure water with no explicit
ions**, rather than at the 0.15 M NaCl physiological salt concentration
applied to all other 15 systems. This affects ionic screening/Debye
length in the simulation, not overall charge balance — a real, disclosable
methodological difference in solvent composition, but a narrower one
than an uncompensated net charge would have been. This should be
disclosed explicitly wherever `02_fidelity_ligand`'s results are
discussed in the dissertation (e.g. as a stated limitation on solvent
ionic strength for this one seed), since a reader comparing its
trajectory to the other 13 analysed systems should know this difference
exists.
