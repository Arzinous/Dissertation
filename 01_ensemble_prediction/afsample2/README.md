# AFsample2 — Ensemble Prediction for IL-2

## Purpose

AFsample2 (Kalakoti & Wallner, 2025) generates conformational diversity
by randomly masking a percentage of AlphaFold2's input MSA columns to
"X" for every prediction, combined with stochastic inference dropout —
the principled successor to MSA Subsampling's crude depth-truncation
approach, integrated directly into AlphaFold2's own codebase rather than
manipulated externally.

## Software / Environment

- **Container**: `afsample2_v1.1.sif` (Apptainer image, 6.1 GB), built
  13 July 2026 from `docker.io/kyogesh/afsample2:v1.1` (Ubuntu 20.04
  base, cuDNN 8.9.6.50, Apptainer 1.5.2).
- Run via a dedicated `apptainer` conda environment (`conda activate
  apptainer`) — the container itself bundles AFsample2's AlphaFold2 fork,
  so the host-side conda env only needs to provide Apptainer/Singularity
  itself, not the ML stack.
- Supporting host-side dependency spec: `config/AFsample2_environment.yaml`
  (Python-adjacent tooling — OpenMM, PDBFixer, HHsuite, HMMER, MMseqs2 —
  used for input preparation rather than the prediction step itself,
  which runs entirely inside the container).
- AlphaFold2 model parameters mounted read-only from the host's shared
  ColabFold params cache (`~/.cache/colabfold/params`), reused across
  methods rather than duplicated.

## Input

- `input/il2/il2.fasta` — confirmed identical (byte-for-byte `diff`) to
  the shared `../shared_input/IL-2_pdb_1M47.fasta` used across all three
  ensemble methods.
- `input/il2/il2.a3m` — the MSA supplied to AFsample2. Confirmed to
  contain the **same underlying alignment** (identical query header and
  full sequence content) as `~/projects/IL2_MSA_subsampling/msa/IL-2_pdb_1M47.a3m`,
  satisfying the shared-MSA design intended to avoid confounding
  cross-method comparisons with different alignments. It is **not**
  byte-identical, however: `il2.a3m` is missing a single header line,
  `#133 1` (a length/sequence-count directive), present at the top of
  the MSA Subsampling copy. `input/il2/il2_original.a3m` retains that
  header line; `il2.a3m` was evidently derived from it by stripping that
  one line before being passed to AFsample2. This is unlikely to affect
  AF2's actual co-evolutionary inference (the sequence content itself is
  unchanged), but it means the input is not a byte-for-byte identical
  file across methods — worth stating precisely rather than claiming
  full identity.

## The sweep

Four `msa_rand_fraction` conditions, run **in parallel across 4 GPUs**
(one condition per device via `CUDA_VISIBLE_DEVICES` pinning — AF2/
AFsample2 cannot split a single prediction across multiple GPUs, so
parallelism here is at the condition level, not within a run):

| Condition | `msa_rand_fraction` | GPU | `nstruct` | Models produced |
|---|---|---|---|---|
| `frac_010` | 0.10 | 0 | 10 | **50 (confirmed)** |
| `frac_015` | 0.15 | 1 | 10 | **50 (confirmed)** |
| `frac_020` | 0.20 | 2 | 10 | **50 (confirmed)** |
| `frac_030` | 0.30 | 3 | 10 | **50 (confirmed)** |

50 models per condition = 5 AF2 model weights × `nstruct=10` (confirmed
against log output: `model_1` through `model_5`, each run to
`model_5_pred_10`). **Total: 200 models** across the 4-condition sweep.

Shared parameters across all conditions: `--msa_perturbation_mode=random`,
`--model_preset=monomer`, `--dropout=True` (stochastic inference dropout
enabled — this, combined with MSA column masking, is what distinguishes
AFsample2's diversity mechanism from MSA Subsampling's depth-only
approach), `--flagfile=/app/alphafold/AF_multitemplate/monomer_full_dbs.flag`.

**Verified correct, not a units bug:** the run logs report e.g.
"Randomization 0.1 %" for the `frac_010` condition (launched with
`--msa_rand_fraction=0.10`). This is simply the tool echoing the fraction
value as a percentage without a trailing zero, not a 100x discrepancy —
confirmed by (a) the reported value scaling correctly across all four
conditions (0.1/0.15/0.2/0.3, matching 0.10/0.15/0.20/0.30 exactly) and
(b) directly counting perturbed positions (marked `*`) in the logged
per-structure sequence maps, which increase with condition as expected
(`frac_010`: ~8 perturbed positions per structure; `frac_030`: ~25+).

There is also a `smoke_test/` output directory (5 models) predating the
real sweep by several hours — this is a preliminary validation run
confirming the container/pipeline worked end-to-end, **not** part of the
4-condition sweep data, and should not be included in downstream
ensemble analysis.

## Output

`outputs/{condition}/il2/` per condition, each containing:
- `afsample2/` — the actual predicted structures
- `msas/` — per-run MSA/feature intermediates
- `features.pkl` — AF2 input feature dictionary

Packaged as `IL2_AFsample2_200.tar.gz` (12.6 MB, 200 models) for transfer
off the HPC — note this filename reflects only the 4-condition sweep
total (200), correctly excluding the 5 `smoke_test` models.

## Reproduce

```bash
conda activate apptainer
cd ~/projects/afsample2
bash scripts/run_il2_afsample2_sweep.sh
```

Requires: the `afsample2_v1.1.sif` container image, an NVIDIA GPU with
`--nv` Apptainer support, and AlphaFold2 model parameters available at
the bind-mounted path (`~/.cache/colabfold/params`). Runtime: ~40 min for
all 4 conditions in parallel on the deployed hardware (per log
timestamps, first structure ~18:35, condition completion ~19:13).

Feed the resulting ensemble into `../../02_ensemble_analysis/` for
structural fidelity / diversity scoring against the crystallographic
reference library.
