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
| MSA Subsampling `02_fidelity_ligand` | *(logs not located — see modelling_scripts/README.md)* | — | — |
| MSA Subsampling `03_transition_state` | 366.89 | 33 | 33 |
| MSA Subsampling `04_diversity_representative` | 382.83 | 35 | 35 |
| MSA Subsampling `05_discordance` | 378.26 | 34 | 34 |
| BioEmu `01_centroid_01` | 405.78 | 37 | 37 |
| BioEmu `02_centroid_02` | 350.23 | 32 | 32 |
| BioEmu `03_centroid_03` | 449.99 | 41 | 41 |

Two logging gaps noted rather than filled in: AFsample2
`03_transition_state`'s `editconf.log` wasn't located at the expected
path (ion counts were still recoverable from its `genion.log`), and
MSA Subsampling `02_fidelity_ligand` has no located logs for this stage
at all — consistent with the same system's missing `pdb2gmx.log` noted
in `../modelling_scripts/README.md`. This system's logging appears
incomplete across multiple pipeline stages, worth a targeted check
outside the ~/.bash_history/log-mining approach used here (e.g.
confirming whether its files are simply misplaced/renamed rather than
genuinely absent) if time allows before submission.
