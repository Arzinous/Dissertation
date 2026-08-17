# Data Setup

Tracks exactly what's in this repository as of the last update, and
what still needs to be added. Git and Git LFS are already initialised
in this repo (`git init` + `git lfs install` already run; `.gitattributes`
already tracks `*.xtc`, `*.trr`, `*.cpt`, `*.edr`, `*.tar.gz`, `*.npz`,
`*.sif`).

## Already committed

- **`02_ensemble_analysis/data/raw/`** — complete: reference library
  (apo/holo/ligand PDBs), MSA Subsampling (200 models, 5 conditions),
  AFsample2 (200 models, 4 conditions), BioEmu (1000 samples, topology +
  200 `.npz` batches). Verified directly against the notebook's own
  loader/parsing code before committing.
- **`03_md_simulations/production_data/`** — replicate 1 (`npt.gro` +
  `production.xtc`) for 6 of 14 systems: `apo_1M47`, `receptor_1Z92`,
  `open_1PY2`, `ai_seeds_MSA_Subsampling_02_fidelity_ligand`,
  `_03_transition_state`, `_04_diversity_representative`. All verified
  complete (`Finished mdrun`, step 5,000,000 = 10 ns) before committing.
- Both notebooks (`02_ensemble_analysis/`, `04_trajectory_analysis/`),
  with `Appendix2_TrajectoryAnalysis.ipynb`'s 4 root paths rewritten
  from absolute macOS paths to relative paths for portability.
- All Workflow 1–4 documentation, `.mdp` files, `ACKNOWLEDGEMENTS.md`.

## Still needed — exact list

### A. Replicate 1 (`03_md_simulations/production_data/{name}/`)

8 folders remaining, each needs `npt.gro` + `production.xtc`:

```
ai_seeds_MSA_Subsampling_05_discordance
ai_seeds_AFsample2_02_fidelity_ligand
ai_seeds_AFsample2_03_transition_state
ai_seeds_AFsample2_04_diversity_representative
ai_seeds_AFsample2_05_discordance
ai_seeds_BioEmu_01_centroid_01
ai_seeds_BioEmu_02_centroid_02
ai_seeds_BioEmu_03_centroid_03
```

### B. Replicates 2 & 3 (`03_md_simulations/replicates_data/{name}/replica_0{2,3}/`)

All 14 systems need this. Each `replica_02/` and `replica_03/` needs
`production.xtc` (required) — `npt.gro` is optional; if absent, the
notebook falls back to replicate 1's `npt.gro` as topology.

**Naming — use these exact folder names** (per
`Appendix2_TrajectoryAnalysis.ipynb`'s `REPLICA_DIR_ALIASES`, confirmed
against your local `Replicas/` folder structure):

```
apo_1M47
receptor_1Z92
open_1PY2
MSA_02_fidelity_ligand            <- aliased name, NOT ai_seeds_MSA_Subsampling_...
MSA_03_transition_state           <- aliased
MSA_04_diversity_representative   <- aliased
MSA_05_discordance                <- aliased
ai_seeds_AFsample2_02_fidelity_ligand
ai_seeds_AFsample2_03_transition_state
ai_seeds_AFsample2_04_diversity_representative
ai_seeds_AFsample2_05_discordance
ai_seeds_BioEmu_01_centroid_01
ai_seeds_BioEmu_02_centroid_02
ai_seeds_BioEmu_03_centroid_03
```

Do **not** include `ai_seeds_AFsample2_01_fidelity_apo` or
`MSA_01_fidelity_apo` — both correctly excluded from analysis (see
`03_md_simulations/seeds/README.md`).

### C. Optional

`04_trajectory_analysis/data/md_seeds/seed_ss_by_residue.csv` — read
defensively by the notebook (`if os.path.exists(...) else None`), so
not required for the notebook to run, just for one supplementary
cross-reference (Section 5, RMSF vs. static secondary-structure flags).

## How to continue from here

1. Unpack this repo wherever you'll do the final `git push` from.
2. Copy the remaining files from your local `Replicas/` folder (per
   your screenshot) into `03_md_simulations/production_data/` (for the
   8 replicate-1 folders above) and `03_md_simulations/replicates_data/`
   (for all 14 systems' replicate 2/3), matching the exact names above.
3. From the repo root:
   ```bash
   git lfs install        # if not already done on this machine
   git add .
   git commit -m "Add remaining production trajectories and replicates"
   ```
4. Push to GitHub (create the remote repo first if not done):
   ```bash
   git remote add origin <your-github-repo-url>
   git branch -M main
   git push -u origin main
   ```
5. Verify before submission:
   ```bash
   git lfs ls-files              # confirm large files are LFS-tracked, not raw blobs
   du -sh .git                   # sanity-check total repo size
   ```

## Not to include

`afsample2_v1.1.sif` (6.1 GB Apptainer container) — reference by name/
version/source only (already documented in
`01_ensemble_prediction/afsample2/README.md`), don't commit the binary.
