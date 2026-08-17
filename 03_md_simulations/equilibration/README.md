# Equilibration (NVT + NPT)

## Method

Two-stage equilibration following energy minimisation, both with the
protein position-restrained (`-DPOSRES`) while solvent relaxes around
it:

1. **NVT** (`../mdp/nvt.mdp`): 100 ps, 300 K, constant volume,
   V-rescale thermostat, velocities freshly generated
   (`gen-vel=yes`, `gen-seed=-1`).
2. **NPT** (`../mdp/npt.mdp`): 100 ps, 300 K / 1 bar, constant pressure,
   V-rescale thermostat + C-rescale barostat (isotropic,
   `compressibility=4.5e-5`), continuing directly from NVT
   (`continuation=yes`).

Both stages: LINCS constraints on h-bonds, PME electrostatics, Verlet
cutoff scheme — consistent with minimisation and production settings.

## Reference case: `apo_1M47`, replica_01

Confirmed via `gmx energy` directly against the `.edr` files (not
estimated):

**NVT** (100 ps, 501 data points):

| Quantity | Average | Err. Est. | RMSD | Tot-Drift |
|---|---|---|---|---|
| Temperature (K) | 299.85 | 0.27 | 3.237 | 1.670 |

Target 300 K achieved essentially exactly (299.85 K average) — good
thermal equilibration.

**NPT** (100 ps, 501 data points):

| Quantity | Average | Err. Est. | RMSD | Tot-Drift |
|---|---|---|---|---|
| Temperature (K) | 300.007 | 0.15 | 1.428 | 0.447 |
| Pressure (bar) | −16.965 | 11 | 112.82 | 75.599 |
| Density (kg/m³) | 1003.27 | 0.56 | 2.908 | 3.783 |

Temperature remains tightly controlled. Pressure shows large
instantaneous fluctuation (RMSD ≈ 113 bar) around a negative mean
(−17 bar) rather than sitting at the 1 bar reference — this is
**expected and not a sign of a poorly-equilibrated system**: pressure is
a highly noisy instantaneous quantity in a system this size over a short
100 ps window, and C-rescale barostat convergence is judged by whether
**density** stabilises near the physically expected value, which it
does here (1003.27 kg/m³, close to bulk water's ~997 kg/m³ at 300 K).

## Other systems

This level of `gmx energy` verification (NVT/NPT temperature, pressure,
density statistics) has been performed in depth for `apo_1M47` as the
reference case, and equivalent NVT/NPT statistics were independently
confirmed for AFsample2 `04_diversity_representative`, BioEmu
`02_centroid_02`, and BioEmu `03_centroid_03` via their respective
gap reports (all show temperature converging to ~300 K and density
converging to ~1000–1012 kg/m³, consistent with proper equilibration).
Full `gmx energy` verification for the remaining systems was not
completed in this pass — the `.edr` files needed are present on disk
for all systems and the same commands used above can be applied
directly if a complete appendix table is wanted before submission.

## Confirmed methods detail carried over from seeds documentation

`BioEmu/03_centroid_03`'s NPT stage required one retry after an initial
failed attempt — see `../seeds/README.md` for the full account (archived
failed-attempt files, confirmed successful rerun, and the one item that
could not be independently verified: NVT's own log/gro files for this
specific system).
