#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=4GB
#SBATCH --job-name=Dolphyn_SmallNewEngland
#SBATCH --mail-type=END
#SBATCH --mail-user=ruthvikmukkamala@nyu.edu
#SBATCH --output=slurm_%j.out

module purge
module load julia/1.6.1  # Adjust version as needed


PROJECTDIR="/Users/ruthvikmukkamala/PycharmProjects/Dolphyn.jl"

julia --project=$PROJECTDIR -e '
    using Pkg;
    Pkg.add("Gurobi");
    Pkg.build("Gurobi");

    cd("/Users/ruthvikmukkamala/PycharmProjects/Dolphyn.jl/Test_1_Rep_60_RPS_Hourly/1_Rep_VRE_Scenarios_Hourly_C0");
    include("Run.jl");
'