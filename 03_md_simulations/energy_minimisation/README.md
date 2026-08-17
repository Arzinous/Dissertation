# Energy Minimisation

## Method

Steepest descents, `emtol=1000.0` kJ/mol/nm, `emstep=0.01`,
`nsteps=50000` maximum (see `../mdp/minim.mdp`). Verlet cutoff scheme,
PME electrostatics, no constraints during minimisation.

## Convergence — all 16 systems

All 16 systems converged successfully (Fmax < 1000 kJ/mol/nm) well
within the 50,000-step budget:

| System | Steps to converge | Potential energy (kJ/mol) | Max force (kJ/mol/nm) |
|---|---|---|---|
| `apo_1M47` (reference) | 1468 | −8.296×10⁵ | 967.1 |
| `open_1PY2` (reference) | 1028 | −8.469×10⁵ | 945.1 |
| `receptor_1Z92` (reference) | 514 | −7.127×10⁵ | 964.4 |
| AFsample2 `01_fidelity_apo` | 888 | −6.125×10⁵ | 976.9 |
| AFsample2 `02_fidelity_ligand` | 860 | −6.114×10⁵ | 951.3 |
| AFsample2 `03_transition_state` | 863 | −6.100×10⁵ | 949.9 |
| AFsample2 `04_diversity_representative` | 884 | −6.209×10⁵ | 981.1 |
| AFsample2 `05_discordance` | 841 | −5.502×10⁵ | 985.8 |
| MSA Subsampling `01_fidelity_apo` | 989 | −6.129×10⁵ | 934.5 |
| MSA Subsampling `02_fidelity_ligand` | 745 | −5.047×10⁵ | 978.6 |
| MSA Subsampling `03_transition_state` | 994 | −5.749×10⁵ | 868.9 |
| MSA Subsampling `04_diversity_representative` | 793 | −6.002×10⁵ | 977.8 |
| MSA Subsampling `05_discordance` | 1080 | −5.942×10⁵ | 921.0 |
| BioEmu `01_centroid_01` | 1118 | −6.387×10⁵ | 944.6 |
| BioEmu `02_centroid_02` | 803 | −5.419×10⁵ | 942.8 |
| BioEmu `03_centroid_03` | 1190 | −7.113×10⁵ | 850.9 |

Reference structures generally show more negative potential energy than
AI-seeded systems, broadly tracking their larger box/solvent content
(see `../box_solvation_ionisation/README.md`) rather than indicating any
difference in per-system structural quality — box size, not structure
quality, is the dominant driver of total potential energy here since
solvent contributes the majority of atoms in every system.
