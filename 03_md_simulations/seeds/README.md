# MD System Setup — Seeds

## Overview

16 independent MD systems were prepared and run; **14 are included in
downstream trajectory analysis** (Section 4 of the dissertation). This
README documents the full inventory, which 2 structures were excluded
from analysis and why, and one confirmed equilibration retry worth
recording as a methods detail.

## Full inventory (16 systems run)

### Reference structures (3)

| Directory | Source | Role |
|---|---|---|
| `apo_1M47` | PDB 1M47 | Apo ground state reference |
| `open_1PY2` | PDB 1PY2, chain D | Cryptic-pocket / ligand-bound reference |
| `receptor_1Z92` | PDB 1Z92 | IL-2Rα-bound holo reference |

### AFsample2 seeds (5 run, 4 analysed)

| Directory | Seeding criterion | In analysis? |
|---|---|---|
| `01_fidelity_apo` | Apo-fidelity | **Excluded** — see rationale below |
| `02_fidelity_ligand` | Ligand-fidelity | Included |
| `03_transition_state` | Transition-state | Included |
| `04_diversity_representative` | Diversity-representative | Included |
| `05_discordance` | Discordance | Included |

### MSA Subsampling seeds (5 run, 4 analysed)

Same 5 seeding criteria and same exclusion as AFsample2 (see rationale
below):

| Directory | Seeding criterion | In analysis? |
|---|---|---|
| `01_fidelity_apo` | Apo-fidelity | **Excluded** |
| `02_fidelity_ligand` | Ligand-fidelity | Included |
| `03_transition_state` | Transition-state | Included |
| `04_diversity_representative` | Diversity-representative | Included |
| `05_discordance` | Discordance | Included |

### BioEmu seeds (3 run, 3 analysed)

| Directory | Seeding criterion | In analysis? |
|---|---|---|
| `01_centroid_01` | Cluster centroid 1 | Included |
| `02_centroid_02` | Cluster centroid 2 | Included |
| `03_centroid_03` | Cluster centroid 3 | Included |

Only 3 seeds (cluster centroids, not the 5-criterion fidelity/diversity/
transition-state/discordance scheme used for the other two methods) —
an explicit, deliberate limitation, not an oversight: BioEmu showed
near-zero fidelity classification across all three reference states for
IL-2, so the 5-criterion fidelity/discordance framework used for
AFsample2 and MSA Subsampling was not meaningfully applicable, and
cluster-centroid selection was used instead.

**Total run: 16 (3 + 5 + 5 + 3). Total in analysis: 14** (16 minus the 2
excluded `01_fidelity_apo` seeds, one each from AFsample2 and MSA
Subsampling).

## Compute infrastructure note

All 16 systems share a single project directory on a common home
filesystem, but **production MD for 4 systems ran on `chegpu004`
rather than `chegpu002`**: AFsample2 `04_diversity_representative`,
AFsample2 `05_discordance`, BioEmu `02_centroid_02`, and BioEmu
`03_centroid_03`. This was confirmed directly (not assumed) after an
initial completeness sweep on `chegpu002` alone showed these 4 systems
missing 1–3 of their 3 production replicas — `chegpu002`'s own SLURM
history (`sacct`/`squeue`) has no record of these jobs, because they
were submitted and run from `chegpu004`, whose job accounting is
separate. A direct `md5sum` check on one system's `topol.top`, run
independently from both machines, confirmed an identical hash — the two
nodes share the same underlying project filesystem rather than holding
divergent copies. **All 12 replicas across these 4 systems are confirmed
complete** (`Finished mdrun`, final step 5,000,000 = exactly 10 ns),
verified directly on `chegpu004`.

This is worth stating explicitly in the dissertation methods section:
production MD was distributed across two GPU nodes (`chegpu002`,
`chegpu004`) sharing common storage, rather than run entirely on one
machine — a legitimate infrastructure detail, not a data-completeness
issue.

## Why `01_fidelity_apo` is excluded from AFsample2 and MSA Subsampling

IL-2's three reference states (apo, holo, cryptic-pocket/ligand-bound)
differ only subtly from one another structurally (consistent with the
lit review, Section 4.5: the cryptic-pocket transition is a locally
gated Phe42 rotamer switch against an otherwise conserved fold, not a
large-scale rearrangement). As a consequence, for both AFsample2 and MSA
Subsampling, the AI-predicted seed selected under the "apo-fidelity"
criterion and the seed selected under the "ligand-fidelity" criterion
converged to essentially the same structure — sitting within the common
conformational space shared by all three states rather than being
distinctly representative of either endpoint alone.

Running both as separate, near-duplicate MD simulations would have added
no meaningful independent information, so a single fidelity
representative (`02_fidelity_ligand`) was retained per method and
`01_fidelity_apo` was excluded from analysis. **The raw MD output for
`01_fidelity_apo` still exists on disk for both methods and is not
deleted** — it is a legitimate completed simulation, simply not carried
into the Results section, and should be described this way in the
dissertation (excluded for redundancy, not because the run failed or was
invalid).

## Shared MD parameters

All 16 systems (reference and AI-seeded alike) share the same `.mdp`
parameter files, held centrally at `il2_md/mdp/` rather than duplicated
per system:

| File | Stage | Key settings |
|---|---|---|
| `ions.mdp` | Ion placement | `integrator=steep`, `emtol=1000.0` |
| `minim.mdp` | Energy minimisation | `integrator=steep`, `emtol=1000.0`, `nsteps=50000` |
| `nvt.mdp` | NVT equilibration | (see `../equilibration/README.md`) |
| `npt.mdp` | NPT equilibration | `dt=0.002`, `nsteps=50000` (100 ps), `tcoupl=V-rescale` (300 K), `pcoupl=C-rescale` (1 bar), `constraints=h-bonds`, `continuation=yes` |
| `production.mdp` | Production MD | see `../production/README.md` |
| `production_replicate.mdp` | Production replicates | see `../replicates/README.md` |

All systems: PME electrostatics (`rcoulomb=1.2`), Verlet cutoff scheme,
LINCS constraints on h-bonds, periodic boundary conditions in all three
dimensions.

## Confirmed methods detail: `03_centroid_03` NPT retry

Worth documenting explicitly as a methods/QC detail rather than omitting
it, since catching and correctly resolving a failed run is a genuine
part of the record:

- NPT equilibration for `03_centroid_03` **failed on its first attempt**.
  GROMACS' own automatic backup convention preserved the failed attempt's
  files (`#npt.gro.1#`, `#npt.tpr.1#`, `#npt.log.1#`, `#npt.edr.1#`,
  `#npt.xtc.1#`), later moved into `_archive/` (per
  `_archive/ARCHIVE_MANIFEST.txt`, archived 22 July 2026).
- NPT was **rerun and completed successfully**: confirmed directly from
  the live (non-archived) `npt.log` — `Finished mdrun on rank 0 Tue Jul
  21 20:07:35 2026`.
- The rerun's tmux session was named `bioemu03_nvt_rerun`, which is
  **misleading** — the command actually running inside it was NPT
  (`gmx mdrun -s equilibration/replica_01/npt.tpr -deffnm
  equilibration/replica_01/npt`), not NVT. This is almost certainly a
  carried-over/copy-pasted session name from an earlier NVT session
  rather than evidence that NVT itself needed rerunning.
- **One item that cannot be independently verified from disk**: NVT's
  own `nvt.log`/`nvt.gro` are absent from both the live directory and
  the archive for `03_centroid_03` — only `nvt.tpr` survives. Since NPT
  was launched with `continuation=yes` (requiring NVT's final state as
  input), NVT almost certainly completed successfully, but this cannot
  be directly confirmed from the surviving files. Stated here as an
  honest gap rather than asserted as fact.

No equivalent retry evidence was found for `01_centroid_01` or
`02_centroid_02` in the material reviewed so far.
