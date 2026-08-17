# Ensemble Analysis & MD Seed Selection

`Appendix1_IL2_Ensemble_Analysis.ipynb` — the cleaned, publication-facing
notebook (per its own header, a companion to a working notebook,
`IL2_Conformational_Analysis_Curated.ipynb`, not included in this
repository). This is the analysis that sits between Workflow 1
(Ensemble Prediction) and Workflow 3 (MD Simulations): it takes the raw
predicted ensembles, scores them against a curated crystallographic
reference library on structural fidelity and conformational diversity,
characterises the cryptic-pocket state specifically, and selects the MD
seed structures documented in `../03_md_simulations/seeds/README.md`.

## Structure (94 cells)

| Section | Content |
|---|---|
| 0. Helper Functions | Structure I/O, superposition, RMSD/TM-score, PCA-basis fitting, DSSP, BioEmu backbone reconstruction |
| 1. Data Curation & Validation | Reference ensemble loading + QC; BioEmu full-atom reconstruction |
| 2. Ensemble Analysis | 2.1 Structural similarity (pooled reference RMSD, DSSP recovery, three-way Cα RMSD, RMSD coverage bands); 2.2 Conformational diversity (reference-basis PCA, convex-hull EV score, per-structure DSSP vs. distance-to-reference) |
| 3. State Characterisation | 3.1 Data-driven pocket-lining residue definition; 3.2 χ1 rotamer state (Phe42/Tyr45/Glu62 → reduces to Phe42 alone); 3.3–3.4 Pocket volume/SASA, reference-calibrated then applied to predicted ensembles |
| 4. MD Seed Selection | 4.1 MSA Subsampling/AFsample2 4-criteria selection; 4.2 BioEmu cluster-centroid selection; 4.3 Pre-MD minimisation sanity gate; 4.4 Seed secondary-structure recovery; 4.5 Summary card |

## Data dependencies

Expects a curated local structure at `../data/raw/`, **not** included in
this repository (not part of the uploaded notebook, and not
reconstructable from memory — see Known gap below):

```
data/raw/
├── apo/*.pdb          # pooled reference chains, apo state
├── holo/*.pdb         # pooled reference chains, holo state
├── ligand/*.pdb       # pooled reference chains, ligand-bound/cryptic-pocket state
├── af2_msa_sweep/{condition}/*_unrelaxed_rank_*.pdb   # MSA Subsampling, 5 conditions
├── afsample2/{condition}/...                          # AFsample2, 4 dropout-rate conditions
└── bioemu/...                                          # BioEmu ensemble
```

Confirmed identical to Workflow 1's parameters (good cross-validation
between the two, independently arrived at):
- `MSA_ORDER = ["msa_008_016", "msa_016_032", "msa_032_064", "msa_064_128", "full_msa"]`
- `DROPOUT_ORDER = ["frac_010", "frac_015", "frac_020", "frac_030"]`
- 200 MSA Subsampling models (5 depths × 40 models) — matches
  `../01_ensemble_prediction/msa_subsampling/README.md` exactly
- Notebook's own code comment confirms a **historical labelling bug**:
  `COLOR_MSA` is annotated "was mislabelled 'AFsample2'" in an earlier
  version of this notebook — i.e. MSA Subsampling and AFsample2 outputs
  were once confused with each other and have since been corrected here.
  Worth a one-line mention in the dissertation methods section as a
  caught-and-fixed error rather than leaving it undocumented.

## Reference library — broader than the 3 MD reference structures

Unlike Workflow 3 (which uses one representative structure per state:
`1M47`, `1Z92`, `1PY2`), this notebook pools **multiple PDB structures
per state** into a broader crystallographic reference library (e.g.
`1M47`, `1M4C` for apo; includes `2ERJ` for holo; references `3INK` in
its QC logic), consistent with the OC23-benchmark-style curated library
described in the thesis. This is a deliberately different, larger scope
than the single-structure MD reference set — worth stating explicitly so
the two aren't conflated when read alongside Workflow 3.

**QC screening, with a documented override**: reference chains are
screened for a wild-type Cys125 (excluding common recombinant-expression
C125A/S constructs) and an intact native Cys58–Cys105 disulfide.
`2ERJ` fails the wild-type-Cys125 screen but is explicitly retained
(`QC_OVERRIDE_INCLUDE = {"2ERJ"}`) per a documented rationale in the
notebook itself: C125 only ever contributes a Cα position to the pooled
reference trace (never side-chain identity) in this analysis, and
including it resolves holo's otherwise-insufficient n=2 chain count for
a 2D PCA basis. `3INK` (apo) is deliberately **not** overridden despite
also failing, since apo already has a sufficient n=3 basis without it.
This asymmetric handling is intentional and explained in-notebook, not
an inconsistency.

## Data — now included in this repository

`data/raw/` is included directly in this repository (via Git LFS for
the BioEmu `.npz` batch files), verified to exactly match the structure
every loader function expects:

```
data/raw/
├── apo/*.pdb            (1M47, 1M4C, 3INK)
├── holo/*.pdb            (1Z92, 2B5I, 2ERJ)
├── ligand/*.pdb           (1M48, 1M49, 1PW6, 1PY2)
├── af2_msa_sweep/{full_msa,msa_008_016,msa_016_032,msa_032_064,msa_064_128}/
│       *_unrelaxed_rank_*.pdb + matching *_scores_rank_*.json  (40+40 per condition)
├── afsample2/outputs/{frac_010,frac_015,frac_020,frac_030}/il2/afsample2/
│       unrelaxed_*.pdb  (50 per fraction)
└── bioemu/
        topology.pdb
        batch_*.npz  (200 files, 5 samples each = 1000 total)
```

Every filename pattern was verified directly against the notebook's own
loader/parsing logic (not just checked for presence) before committing —
e.g. AFsample2's `unrelaxed_model_1_pred_10_rand0.1_dropout.pdb` was
confirmed to parse correctly under `load_afsample2_ensemble`'s tag-split
logic, and MSA Subsampling's `_unrelaxed_`→`_scores_` filename swap was
confirmed to resolve to an existing file for a sample case.

## Known gap

**The process used to build this `data/raw/` structure from the raw HPC
outputs (Workflow 1's `.tar.gz` archives) could not be recalled and is
not captured in any script found in this repository** — the data itself
is present and verified, but the exact reorganisation/extraction step
that produced this folder layout from the raw archives is not
documented. Stated plainly rather than reconstructed. If this notebook
is not yet referenced in the dissertation write-up (confirmed as of an
earlier pass in this conversation), this gap should be resolved or
explicitly flagged before the notebook is cited in the Methods section.

## Output

11 selected MD seeds (4 criteria × 2 methods for MSA Subsampling/
AFsample2, + 3 cluster centroids for BioEmu) — matches
`../03_md_simulations/seeds/README.md`'s 14-system analysis set exactly
once the 3 reference structures are added (11 + 3 = 14). Seeds pass a
pre-MD OpenMM/PDBFixer minimisation sanity gate (Section 4.3) before
being handed to Workflow 3.
