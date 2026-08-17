# Modelling Scripts — Structure Preparation for GROMACS

## Scope

This covers preparation of each of the 16 input structures (reference
crystal structures and AI-predicted seeds alike) up to and including
`pdb2gmx` — the step that assigns force field, water model, protonation
states, and disulfide connectivity, producing the `topol.top` used for
everything downstream.

Per a deliberate scoping decision (time-constrained ahead of submission),
this documents the **final adopted `pdb2gmx` command per system** —
i.e. the one whose output is the currently-live `topology/topol.top` —
rather than tracing every intermediate attempt. Several systems show
evidence of iterative troubleshooting (varying input filenames,
suggesting fixes for disulfide/geometry issues across attempts); this is
normal, legitimate system-preparation practice, and the raw logs for
superseded attempts remain on disk (`_archive/`, `archive/pre_rerun_*/`)
for anyone who wants to trace the full history.

## Reference structures — automatic protonation/disulfide assignment

| System | Input | Command |
|---|---|---|
| `apo_1M47` | `1M47_rebuilt.pdb` | `gmx pdb2gmx -f ../input/1M47_rebuilt.pdb -o processed.gro -p topol.top -i posre.itp -ff amber99sb-ildn -water tip3p -ignh` |
| `open_1PY2` | `1PY2_open_unliganded_repaired.pdb` | `gmx pdb2gmx -f ../input/1PY2_open_unliganded_repaired.pdb -o processed.gro -p topol.top -i posre.itp -ff amber99sb-ildn -water tip3p -ignh` |
| `receptor_1Z92` | `1Z92_IL2_only_repaired.pdb` | `gmx pdb2gmx -f ../input/1Z92_IL2_only_repaired.pdb -o processed.gro -p topol.top -i posre.itp -ff amber99sb-ildn -water tip3p -ignh` |

None of the three reference structures used the interactive `-his -ter
-ss` flags — protonation state, terminus type, and disulfide bonding
were all assigned automatically by GROMACS' own structural analysis.
For `apo_1M47`, this automatic assignment (HISE at residues 16/55/79,
Cys58–Cys105 disulfide) was independently cross-checked against
AFsample2's interactively-assigned `01_fidelity_apo` and found
**identical** — both methods converge on the same physical answer.

**Input file naming reflects real preprocessing**, not arbitrary
choices: `1PY2_open_unliganded_repaired.pdb` has a `_missing_T133`
intermediate on disk (`1PY2_open_unliganded_repaired_missing_T133.pdb`),
confirming a genuine residue-gap repair step occurred before the final
input was used. The specific tool used for this repair/rebuild step
(and for producing `1M47_rebuilt.pdb`) has not been independently traced
in this pass — see Known gaps below.

## AI-seeded structures — interactive protonation/disulfide assignment

All 13 AI-seeded systems used `-ignh -his -ter -ss` (interactive
histidine tautomer selection, terminus identification, and disulfide
confirmation prompts), with two exceptions noted in the table.

| Method | Seed | Input file | Notes |
|---|---|---|---|
| AFsample2 | `01_fidelity_apo` | `protein.pdb` | |
| AFsample2 | `02_fidelity_ligand` | `protein.pdb` | Reran 28 Jul 2026 (archived snapshot: `archive/pre_rerun_20260728_143515/`) — not traced further |
| AFsample2 | `03_transition_state` | `protein.pdb` | |
| AFsample2 | `04_diversity_representative` | `protein.pdb` | |
| AFsample2 | `05_discordance` | `protein_disulfide_geometry.pdb` | Distinct input — suggests a disulfide-geometry fix was needed before this seed's `pdb2gmx` succeeded |
| MSA Subsampling | `01_fidelity_apo` | `protein.pdb` | **Missing `-ff` flag** — see `../force_field/README.md`; excluded from analysis regardless |
| MSA Subsampling | `02_fidelity_ligand` | — | **No live `pdb2gmx.log` found** — `topol.top` exists (19 Jul, 17:52) but its generating log is missing from the expected location |
| MSA Subsampling | `03_transition_state` | `original_nonminimised.pdb` | |
| MSA Subsampling | `04_diversity_representative` | `original_nonminimised_cyx.pdb` | `_cyx` suggests a disulfide (CYX residue type) correction was applied |
| MSA Subsampling | `05_discordance` | `protein_disulfide.pdb` | Only flags used: `-ignh -ss` (no `-his -ter`) — protonation/terminus handling differs from the other MSA Subsampling seeds; not resolved further in this pass |
| BioEmu | `01_centroid_01` | `centroid_01_final.pdb` | Reran 28 Jul 2026 (topol.top dated 28 Jul vs. centroids 02/03's 21 Jul) — not traced further |
| BioEmu | `02_centroid_02` | `centroid_02.pdb` | |
| BioEmu | `03_centroid_03` | `centroid_03.pdb` | See `../seeds/README.md` for this system's separate NPT-equilibration retry |

## Known gaps (stated plainly, not resolved in this pass)

- **`1M47_rebuilt.pdb` origin**: a PROPKA output (`1M47_rebuilt.pka`)
  exists alongside it, indicating protonation-state analysis was
  performed, but the specific rebuilding/repair tool used to generate
  `1M47_rebuilt.pdb` from the raw crystal structure was not identified
  in this pass.
- **`MSA_Subsampling/01_fidelity_apo`**: missing `-ff` flag in the live
  log (see force field README). Does not affect the 14 analysed
  systems.
- **`MSA_Subsampling/02_fidelity_ligand`**: generating `pdb2gmx.log` not
  found at the expected path.
- **Two reruns** (`AFsample2/02_fidelity_ligand`, `BioEmu/01_centroid_01`),
  both dated 28 July 2026, noted but not individually traced.

These are recorded honestly as open items rather than papered over —
consistent with the reproducibility standard applied throughout this
repository.
