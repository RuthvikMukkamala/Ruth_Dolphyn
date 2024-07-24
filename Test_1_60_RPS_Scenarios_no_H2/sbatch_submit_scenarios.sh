#!/bin/bash

source /etc/profile
module load julia/1.9.2
module load gurobi/gurobi-1000

echo "My SLURM_ARRAY_TASK_ID: " $LLSUB_RANK
echo "Number of Tasks: " $LLSUB_SIZE

# export GUROBI_HOME = "/home/gridsan/mgiovanniello/gurobi1000/linux64"

julia --project=. ./9_Rep_VRE_Scenarios_CRM_w_NG/1_Rep_VRE_Scenarios_no_H2/run_scenarios.jl $LLSUB_RANK $LLSUB_SIZE
