#!/bin/bash

source /etc/profile
module load julia/1.9.2
module load gurobi/gurobi-1000

echo "My SLURM_ARRAY_TASK_ID: " $LLSUB_RANK
echo "Number of Tasks: " $LLSUB_SIZE

# export GUROBI_HOME = "/home/gridsan/mgiovanniello/gurobi1000/linux64"

julia --project=. ./Out_of_sample_w_CRM/Deterministic_Fixed_Annual_C5/run_deterministic_fixed_cap_scenarios.jl $LLSUB_RANK $LLSUB_SIZE
