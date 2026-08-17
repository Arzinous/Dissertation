# MD Trajectory Analysis

`Appendix2_TrajectoryAnalysis.ipynb` — the dynamic counterpart to
Workflow 2's static ensemble analysis. Where Appendix 1 asks "is this
predicted conformation structurally plausible on paper?", this notebook
asks the thesis's secondary research question directly: **do the
pre-simulation seed-selection criteria predict how a seed actually
behaves once allowed to move?**

## Scope — 14 systems, matching Workflow 3 exactly

Independently confirmed a third time (alongside Workflow 3's own docs
and Appendix 1's own count): the notebook's `SYSTEMS` registry lists
exactly **14 systems** — 3 crystallographic references (`apo_1M47`,
`receptor_1Z92`, `open_1PY2`) + 4 MSA Subsampling seeds + 4 AFsample2
seeds + 3 BioEmu centroids. `01_fidelity_apo` is correctly absent for
both MSA Subsampling and AFsample2, consistent with the exclusion
documented in `../03_md_simulations/seeds/README.md`.

Each system: up to 3 independent 10 ns replicates (replicate 1 continues
NPT's momentum; replicates 2–3 use independently randomised velocities
from the shared NPT endpoint) — matching
`../03_md_simulations/production/README.md` exactly.

## Structure

| Section | Content |
|---|---|
| 0. Setup | Environment, constants recomputed fresh from source (not hardcoded from Appendix 1), trajectory-loading and system-registry glue |
| 1. Introduction and Scope | Research question, 14-system count, seed-group relabelling |
| 2. System Discovery | Confirms which replicates actually exist on disk per system |
| 3. Selection-Philosophy Framework | Maps each seed's selection criterion onto its analysis group |
| 4. Structural Similarity | 4.1 Whole-protein Cα RMSD vs. time; 4.2 Binding-site Cα RMSD vs. time — both with a **Reproducibility** subsection (inter-replicate plateau spread) and an **Interpretation** subsection |
| 5. RMSF Analysis (Supplementary) | Per-residue fluctuation, cross-referenced against Appendix 1's static secondary-structure mismatch flags |
| 6. PCA Convex-Hull Overlap | Area and density overlap against pooled reference-simulation ensembles, per PCA basis |
| 7. Landmark-Specific State Recovery | Per-frame occupancy against state-specific criteria |

Every analysis section follows the same pattern: result → **Reproducibility**
(inter-replicate consistency, flagged where SD exceeds half the mean) →
**Interpretation**. This directly operationalises the "reproducibly
across independent replicates" part of the thesis's secondary research
question, rather than treating reproducibility as an afterthought.

## Central finding, confirmed in the notebook's own words

**Reproducibility tracks the seed's generating architecture, not its
selection criterion.** Fidelity and transition-state seeds are
reproducible for both AlphaFold2-based methods (MSA Subsampling,
AFsample2); BioEmu's three diversity centroids are consistently the
least reproducible systems in the dataset (e.g. RMSD plateau ranks 7, 8,
14 of 14). This matches the interpretive framing already established in
memory from earlier conversations: MSA Subsampling and AFsample2 stay
anchored under perturbation (single-answer networks), while BioEmu
samples a generative equilibrium ensemble with no equivalent anchor.
Good to see the notebook arrives at this independently and states it
explicitly rather than requiring external interpretation.

## Data dependencies

Reads processed trajectory files (`.gro` + `.xtc`) from two separate
local roots — `PRODUCTION_ROOT` (replicate 1) and `REPLICAS_ROOT`
(replicates 2–3) — rather than Workflow 3's raw HPC directory structure
(`runs/{system}/production/replica_0{1,2,3}/` all under one system's own
tree). This is a local reorganisation, not a different underlying
dataset: values are read from the same `production.xtc`/`npt.gro` files
documented in `../03_md_simulations/production/README.md`.

**Known naming quirk, already caught and documented in-notebook** (not
found independently in this pass, credited to the notebook's own
comments): MSA Subsampling's replicate-2/3 directories use an alias
naming convention (`MSA_0N_<criterion>`) differing from the
`ai_seeds_MSA_Subsampling_0N_<criterion>` convention used for replicate 1
and every other system. Confirmed by direct directory listing per the
notebook's own comment, not assumed.

## Known gap

**The reorganisation step that produced the local `PRODUCTION_ROOT`/
`REPLICAS_ROOT` structure from Workflow 3's raw HPC output was not
traced in this pass** — consistent with the same category of gap
already flagged for Appendix 1's `../data/raw/` structure
(`../02_ensemble_analysis/README.md`, "Known gap"). Both notebooks
expect a locally reorganised copy of HPC data rather than reading the
HPC directory structure directly; the exact reorganisation script/process
was not recovered. Stated plainly rather than reconstructed.

## Reference

Reference (crystallographic-seeded) trajectories are explicitly treated
as an **empirical ceiling, not an idealised target** — the notebook
itself notes they show incomplete short-timescale behaviour too
(Section 7), avoiding the framing that reference systems are a perfect
gold standard the AI-seeded systems are simply falling short of.
