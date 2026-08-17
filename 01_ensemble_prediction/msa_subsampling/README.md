# MSA Subsampling — Ensemble Prediction for IL-2

## Purpose

Reducing the depth of AlphaFold2's input MSA weakens co-evolutionary
constraints, allowing the model to sample alternative, higher-energy
conformations instead of collapsing onto the single dominant fold
(del Alamo et al., 2022). Applied to IL-2, this is the fast, low-cost
baseline ensemble-generation method — cheaper than AFsample2 and BioEmu,
and a useful diagnostic before the more targeted AFsample2 column-masking
approach.

## Software

- **LocalColabFold**, installed via the `pixi` route (self-contained
  environment — deliberately **not** installed into the `bioemu` conda
  env, since mixing ColabFold's JAX with another JAX/PyTorch environment
  is unreliable).
- Binary location: `software/localcolabfold/.pixi/envs/default/bin/colabfold_batch`
- **ColabFold version: 1.6.1** (commit `d04bf9c8a9980807c270f9597c85ce754d9cd42b`),
  confirmed from run logs and `config.json` — *not* 1.5.5 as an earlier
  install note suggested; the installed version at run time was 1.6.1.
- Model type: `alphafold2_ptm`
- Version independently confirmed from run logs and every condition's
  own `config.json` (`"version": "1.6.1"`), so this is not in doubt
  despite the CLI `--version` check itself failing twice (path/execution
  errors on the HPC side — not investigated further since the version is
  already confirmed by other means).

## Input

- `../shared_input/IL-2_pdb_1M47.fasta` (133-residue IL-2 sequence, from
  PDB 1M47 chain A)
- MSA was captured **once** from the public MMseqs2 server on the first
  `colabfold_batch` call, saved as `IL-2_pdb_1M47.a3m`, then reused as
  input for every subsequent condition in the sweep — ensuring the only
  variable across conditions is the subsampling depth, not the alignment
  itself.

## Baseline (full-depth) run

A single default-parameter run, `max_seq=512, max_extra_seq=5120`
(effectively no subsampling), producing 5 models — one per AF2 parameter
set, seed 0. This serves as the "no intervention" control against which
the shallow-MSA sweep is compared.

Exact parameters: see `config/baseline_full_depth_config.json` (captured
directly from the run's own `config.json` output — this is ColabFold's
record of the fully-resolved parameters, not a reconstruction).

Result: pLDDT 81.6–87.6, pTM 0.783–0.847 across the 5 models — high
confidence, consistent with collapsing onto the dominant crystallographic
fold, as expected for full-depth MSA.

**Note:** `num_relax: 0` — these are unrelaxed AF2 output structures (no
Amber relaxation step). All downstream RMSD / pocket-volume / rotamer
comparisons in the ensemble analysis notebook were therefore performed
on raw AF2 geometry.

## The depth sweep (the actual experiment)

Five depth conditions, each run as a separate `colabfold_batch` call
against the same fixed `.a3m`, output kept in separate directories so
results stay cleanly attributable to a single depth setting. All
per-condition parameters below are confirmed directly from each
condition's own `config.json` (ColabFold's own record of fully-resolved
run parameters — not a reconstruction):

| Condition | `max_seq` | `max_extra_seq` | `num_seeds` | `num_models` | `num_recycles` | Models produced |
|---|---|---|---|---|---|---|
| `full_msa` | 512 | 5120 | 8 | 5 | 3 | **40 (confirmed)** |
| `msa_008_016` | 8 | 16 | 8 | 5 | 3 | **40 (confirmed)** |
| `msa_016_032` | 16 | 32 | 8 | 5 | 3 | **40 (confirmed)** |
| `msa_032_064` | 32 | 64 | 8 | 5 | 3 | **40 (confirmed)** |
| `msa_064_128` | 64 | 128 | 8 | 5 | 3 | **40 (confirmed)** |

**Total: 200 models** (40 × 5 conditions) — confirmed by per-directory
`find ... -iname "*.pdb" | wc -l` counts, which agree with the very
first whole-sweep count taken (`find outputs/IL2_msa_sweep -iname "*.pdb"
| wc -l` → 200). An earlier `ls ... | grep -c ".pdb"`-based count of 430
was investigated and found unreliable (likely counting non-model files
whose names happen to contain `.pdb`, or mis-parsing `ls`'s per-directory
headers when globbing multiple directories at once) — 200 is the
authoritative, cross-confirmed figure.

Note that `full_msa` uses the same deep parameters
(`max_seq=512, max_extra_seq=5120`) as the standalone baseline run
described above, but with `num_seeds=8` rather than a single seed —
i.e. it is the sweep's own internal deep-MSA control, run under
identical launch conditions to the four shallow conditions (same script,
same seed count), rather than being the same run as the baseline.

Command template (per condition — parameters confirmed, exact historical
invocation reconstructed since it could not be recovered verbatim, see
note below):

```bash
colabfold_batch --max-seq <max_seq> --max-extra-seq <max_extra_seq> \
  --num-seeds 8 --num-models 5 --num-recycle 3 \
  <path-to-saved-IL-2_pdb_1M47.a3m> outputs/IL2_msa_sweep/<condition>/
```

**Reproducibility note:** the literal shell commands used to launch the
five sweep conditions were not recoverable from shell history (history
only extends back to command #1927, prior to the 7 July sweep run).
`1M47_1_Chain_A_interleukin-2_Homo_sapiens__9606__env/msa.sh` was
checked and ruled out — it is ColabFold's own auto-generated MMseqs2
search wrapper, not a user-authored sweep driver. The command template
above is therefore reconstructed from each condition's confirmed
`config.json`, which fully specifies every resolved parameter ColabFold
actually used — this is a complete and accurate record of *what ran*,
even though the literal *command line* that produced it is not archived
verbatim. This distinction is stated here explicitly rather than
presenting the template as a captured log.

## Output

`outputs/IL2_msa_sweep/{condition}/` — each contains unrelaxed `.pdb`
models (`*_unrelaxed_rank_NNN_alphafold2_ptm_model_M_seed_SSS.pdb`),
per-model confidence scores (`.json`), and per-condition pLDDT/PAE/coverage
plots. Packaged as `IL2_MSA_subsampling_sweep.tar.gz` (13.5 MB) for
transfer off the HPC.

## Reproduce

1. Install LocalColabFold via pixi (see `software/localcolabfold/`).
2. Run `colabfold_batch <shared_input_fasta> <out_dir>` once to capture
   the server-generated `.a3m`.
3. Run the five depth conditions in the table above, each pointed at the
   saved `.a3m` rather than the raw FASTA, output to a separate directory
   per condition.
4. Feed the resulting ensemble into `../../02_ensemble_analysis/` for
   structural fidelity / diversity scoring against the crystallographic
   reference library.
