# Force Field Selection and Water Model

## Confirmed choice

**AMBER99SB-ILDN** protein force field with **TIP3P** water model, used
across all 16 MD systems (3 reference + 5 AFsample2 + 5 MSA Subsampling +
3 BioEmu).

Confirmed directly from every system's `topol.top`:
```
#include "amber99sb-ildn.ff/forcefield.itp"
#include "posre.itp"
#include "amber99sb-ildn.ff/tip3p.itp"
#include "amber99sb-ildn.ff/ions.itp"
```

Selected via `pdb2gmx -ff amber99sb-ildn -water tip3p` for every system
**except one** (see Known gap below).

## Water box template vs. water model — not a contradiction

`gmx solvate` uses `spc216.gro` as its solvent coordinate template
(`gmx solvate -cs spc216.gro ...`) for every system. This is **not** a
mismatch with the TIP3P water model actually applied: `spc216.gro` is
GROMACS' standard pre-equilibrated water-box coordinate file, used
generically for initial solvent placement regardless of which water
model the topology ultimately assigns. The actual water physics are
governed entirely by the topology's `#include tip3p.itp` line, not by
which coordinate file was used to place the initial solvent molecules.
Stated explicitly here since this can look like an inconsistency to a
reader unfamiliar with the GROMACS workflow.

## Ion parameters

`amber99sb-ildn.ff/ions.itp`, applied via `genion -pname NA -nname CL
-neutral -conc 0.15` (0.15 M NaCl, charge-neutralised) — confirmed
identical across systems checked (see `../box_solvation_ionisation/README.md`).

## Known gap

`MSA_Subsampling/01_fidelity_apo`'s live `pdb2gmx.log` shows a command
**missing the `-ff amber99sb-ildn` flag**:
```
gmx pdb2gmx -f input/protein.pdb -o input/processed.gro -p topology/topol.top \
  -i topology/posre.itp -water tip3p -ignh -his -ter -ss
```
A `topol.top` was nonetheless produced successfully, implying GROMACS
either defaulted or handled force-field selection interactively (not
captured in the log). **This does not affect any of the 14 analysed
systems** — `01_fidelity_apo` is one of the 2 seeds excluded from
analysis for both AFsample2 and MSA Subsampling (see
`../seeds/README.md`) — but is recorded here for completeness rather
than silently omitted, since it is part of the 16 systems actually run.
