#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/projects/afsample2"
cd "$BASE"

run_fraction() {
    local gpu="$1"
    local frac="$2"
    local out="$3"

    APPTAINERENV_CUDA_VISIBLE_DEVICES="$gpu" apptainer run --nv \
        -B "$BASE/input:/input" \
        -B "$BASE/outputs:/outputs" \
        -B "$HOME/.cache/colabfold/params:/databases/params:ro" \
        "$BASE/afsample2_v1.1.sif" \
        --method=afsample2 \
        --fasta_paths=/input/il2/il2.fasta \
        --msa_file=/input/il2/il2.a3m \
        --flagfile=/app/alphafold/AF_multitemplate/monomer_full_dbs.flag \
        --data_dir=/databases \
        --msa_rand_fraction="$frac" \
        --msa_perturbation_mode=random \
        --nstruct=10 \
        --model_preset=monomer \
        --dropout=True \
        --output_dir="/outputs/$out/" \
        > "$BASE/logs/il2_${out}.log" 2>&1
}

run_fraction 0 0.10 frac_010 &
pid1=$!

run_fraction 1 0.15 frac_015 &
pid2=$!

run_fraction 2 0.20 frac_020 &
pid3=$!

run_fraction 3 0.30 frac_030 &
pid4=$!

echo "Started:"
echo "frac_010 PID $pid1"
echo "frac_015 PID $pid2"
echo "frac_020 PID $pid3"
echo "frac_030 PID $pid4"

wait "$pid1" "$pid2" "$pid3" "$pid4"

echo "All AFsample2 runs completed."
