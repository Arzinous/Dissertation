# MD Production and Replicates

## Method

10 ns unrestrained production MD (`../mdp/production.mdp` /
`../mdp/production_replicate.mdp`), `nsteps=5000000` at `dt=0.002` ps.
Same LINCS/PME/Verlet/thermostat/barostat settings as NPT equilibration,
with position restraints removed (`define =` empty) and, for the first
replica of each system, continuing directly from NPT's final state
(`continuation=yes`, using both `-c npt.gro` and `-t npt.cpt` at
`grompp`).

## Replicate design — confirmed

Three replicates per system (`replica_01`, `replica_02`, `replica_03`),
confirmed for `apo_1M47` via each replica's own `grompp_production.log`:

- **`replica_01`**: `grompp -f production.mdp -c equilibration/replica_01/npt.gro -t equilibration/replica_01/npt.cpt` — continues NPT's momentum/checkpoint state directly.
- **`replica_02`** and **`replica_03`**: `grompp -f production_replicate.mdp -c equilibration/replica_01/npt.gro` (no `-t` checkpoint flag) — same starting **coordinates** as `replica_01`, but with `gen-vel=yes`/`gen-seed=-1` in `production_replicate.mdp` assigning fresh, independently-randomised velocities to each.

This is the correct design for genuinely independent replicates: shared
starting structure, decorrelated dynamics. All three replicas branch
from the same `equilibration/replica_01` — `equilibration/replica_02`
(present but empty) is unused.

## Replicate completeness — all 14 analysed systems confirmed complete

A full sweep across all 16 systems confirmed **3/3 production replicas,
each independently verified complete** (`Finished mdrun`, final step
5,000,000 = exactly 10 ns at `dt=0.002`) for every one of the 14
analysed systems. Two of the excluded `01_fidelity_apo` seeds (not part
of the 14) are also fully complete at 3/3.

Four systems' production stage ran on **`chegpu004`** rather than
`chegpu002` — see `../seeds/README.md`, "Compute infrastructure note",
for the full account of how this was confirmed (an initial
`chegpu002`-only sweep appeared to show these 4 systems incomplete;
checking `chegpu004` directly resolved this — all 12 replicas across
these systems are complete, and the two nodes share a common project
filesystem, confirmed via matching file hashes).

## Compute setup

GPU-accelerated via SLURM, confirmed from `apo_1M47/production/replica_01/submit.slurm`:

```bash
#SBATCH --partition=normalrun
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:1
#SBATCH --mem=6G
#SBATCH --time=7-00:00:00

gmx mdrun -s production.tpr -deffnm production -v -nb gpu -pme gpu -bonded gpu -ntmpi 1 -ntomp 8 -pin on
```

All computation (non-bonded, PME, bonded) offloaded to GPU; 8 OpenMP
threads, single MPI rank, 7-day walltime ceiling (well above what a
10 ns run actually requires — a conservative SLURM allocation, not
indicative of expected runtime).

## Completion — `apo_1M47` (reference case)

All three replicas confirmed complete: `grep -c "Finished mdrun"` = 1
for each of `replica_01`, `replica_02`, `replica_03`. Final step
confirmed at `5,000,000 / 10,000.00 ps` — exactly matching the intended
10 ns production length.

Completion verification for the remaining 15 systems' production runs
was not exhaustively performed in this pass (see Equilibration README
for the same scope note) — recommend a `grep -c "Finished mdrun"` sweep
across all `production/replica_*/production.log` files before treating
the full dataset as confirmed-complete for the dissertation's Results
section.
