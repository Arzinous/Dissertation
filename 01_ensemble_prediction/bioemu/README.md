# BioEmu — Ensemble Prediction for IL-2

## Purpose

BioEmu (Microsoft Research) is a diffusion-based generative model that
samples directly from a learned approximation of a protein's equilibrium
conformational distribution, rather than perturbing AlphaFold2's
inference procedure like the other two methods. It is the only one of
the three ensemble-generation methods that gives approximate population
weights alongside structural diversity — but per the lit review (Section
4.3.1), its published benchmarks show a known apo/holo asymmetry
(86% success recovering ligand-bound/holo states vs. only 56% for apo
states), attributed to holo structures being overrepresented in its
training data.

**This asymmetry is directly reflected in the seeding design**: BioEmu
received only 3 cluster-centroid MD seeds, versus 5 seeding criteria each
for MSA Subsampling and AFsample2 — a deliberate, explicitly documented
consequence of BioEmu's near-zero fidelity classification across all
three reference states for this protein, not an oversight or a workflow
gap.

## Software / Environment

- **`bioemu==1.3.1`**, Python 3.11.15, dedicated `bioemu` conda
  environment (`~/miniforge3/envs/bioemu`).
- Setup followed an internally-provided, tested install guide (supervisor-
  supplied), which documents and fixes several non-obvious dependency
  conflicts inherent to BioEmu's design: the diffusion sampler runs in
  **PyTorch**, its AlphaFold2 embedding step runs in **JAX**, and AF2's
  feature pipeline additionally requires **TensorFlow** — three
  frameworks that must share a compatible CUDA/XLA generation in one
  environment.
- Key version pins and why they matter:
  - `jax==0.4.35` / `jaxlib==0.4.35` (BioEmu's own pin)
  - `tensorflow-cpu==2.18.0`, pinned **down** from latest — left
    unpinned, pip installs a newer TensorFlow whose bundled XLA collides
    with the older jaxlib and aborts on the first run
    (`xla/xla_data.proto` database conflict). TF and jaxlib must come
    from the same XLA generation.
  - `protobuf<6.0` — follows automatically once TensorFlow is correctly
    pinned.
  - `CUDA_ROOT` set explicitly (`/usr/local/cuda-13`) — JAX 0.4.35's
    automatic CUDA discovery fails against an incomplete
    `nvidia-cuda-nvcc` pip stub otherwise.
- Full environment captured via `pip freeze` (`bioemu_working_env.txt`)
  and `conda env export` (`bioemu_environment.yml`), both in `config/` —
  frozen immediately after the smoke test passed, per the install guide's
  own recommendation, so the working combination is restorable exactly.

## Input

- `fasta/` — confirmed identical to the shared
  `../shared_input/IL-2_pdb_1M47.fasta` (133-residue sequence, header
  `>1M47_1|Chain A|interleukin-2|Homo sapiens (9606)`).
- BioEmu queries the public ColabFold MMseqs2 server for its AF2
  embedding step by default. **Confirmed deviation from the intended
  shared-MSA design**: unlike MSA Subsampling and AFsample2 (which both
  used the same pre-captured `.a3m`), BioEmu was run against a bare
  `.fasta` (`fasta/IL-2_pdb_1M47.fasta`), not an `.a3m`. Per
  `bioemu.sample --help`: *"If it is not an a3m file, then colabfold will
  be used to generate an MSA and embedding"* — so BioEmu generated its
  own independent alignment/embedding internally rather than reusing the
  shared one. This is corroborated by `~/.bioemu_embeds_cache`, which
  holds a distinct cached embedding (hashed filename, ~102 KB, timestamp
  6 Jul 17:50) computed shortly after the IL-2 FASTA was placed in
  `fasta/` (6 Jul 17:38) — consistent with a fresh, independently-computed
  embedding rather than a reused one.

  **This should be stated explicitly in the dissertation** as a
  methodological deviation from the shared-alignment design set out in
  the lit review (Section 5.1): cross-method comparisons involving
  BioEmu are not guaranteed to be free of alignment-driven confounds in
  the way the MSA Subsampling vs. AFsample2 comparison is. Whether this
  materially affects the results (e.g. if the independently-generated
  MSA happens to closely match the shared one) is a separate empirical
  question worth a quick check (`diff` against the shared `.a3m`) but
  should not be assumed away.

## Runs

Three distinct output runs exist under `outputs/`:

| Run | Samples | Role |
|---|---|---|
| `test-chignolin` | 10 | Official install-guide smoke test (generic 10-residue peptide, not IL-2) — confirms the environment works end-to-end before any real run |
| `IL2_test` | 100 | IL-2-specific intermediate test run — smaller sample count, likely a pre-production validation step |
| `IL2_1000_seed42` | **1000** | **Production run** — confirmed via `.npz` batch-file numbering running from `batch_0000000_0000005` through `batch_0000995_0001000` |

Each run directory contains: `sequence.fasta`, `topology.pdb`, batched
`.npz` files (chunked in groups of 5 samples per file, e.g.
`batch_0000000_0000005.npz`), and a combined `samples.xtc` trajectory
file holding all sampled conformations.

**Reproducibility gap — stated plainly:** the literal `bioemu.sample`
CLI invocation used for `IL2_1000_seed42` (exact flags: `--num_samples`,
`--batch_size_100`, any seed-control flag) was **not recoverable** —
`scripts/` is empty and no log file survived containing the run command.
The directory name (`IL2_1000_seed42`) strongly implies `--num_samples
1000` and some seed value of 42, and 1000 samples matches the packaged
archive name (`IL2_BioEmu_1000_seed42.tar.gz`), but this is an inference
from naming convention and file count, **not a captured literal command**
— this distinction should be stated in the dissertation appendix exactly
as it is here, consistent with the same honest gap already documented
for MSA Subsampling.

## Output

`outputs/IL2_1000_seed42/` — 1000 sampled conformations, packaged as
`IL2_BioEmu_1000_seed42.tar.gz` (8.5 MB) for transfer off the HPC.

## Downstream: MD seeding

Three cluster-centroid structures selected from this ensemble were
carried forward into MD system setup
(`../../03_md_simulations/seeds/BioEmu/`), consistent with the 3-seed
(not 5-seed) design for this method. Provenance for at least one of
these — `02_centroid_02` — is documented in
`~/projects/il2_md/gap_reports_bioemu/02_centroid_02.txt`, which records
the disulfide-bond and histidine-tautomer state confirmed directly from
that seed's `topol.top` during MD topology setup. See
`../../03_md_simulations/seeds/README.md` for the full seed-selection
rationale.

## Reproduce

```bash
conda activate bioemu
python -m bioemu.sample \
  fasta/IL-2_pdb_1M47.fasta \
  1000 \
  outputs/IL2_1000_seed42
```

Confirmed CLI syntax (from `bioemu.sample --help`): positional arguments
`SEQUENCE NUM_SAMPLES OUTPUT_DIR`, **not** `--sequence`/`--num_samples`
flags as an earlier draft of this README incorrectly assumed. Passing a
`.fasta` (not `.a3m`) as `SEQUENCE` means ColabFold generates the MSA
internally — see the shared-MSA deviation note above.

Defaults not overridden here unless otherwise confirmed:
`--batch_size_100=10`, `--model_name=bioemu-v1.1`, `--denoiser_type=dpm`.
Whether the actual `IL2_1000_seed42` run used these defaults or explicit
overrides (e.g. a different batch size, given the observed 5-sample
`.npz` chunking rather than a size implied by the default-10 formula) is
**not confirmed** — the literal command was not recoverable (see
reproducibility gap above). Flag values shown here are the tool's
documented defaults, not a verified record of what actually ran.
