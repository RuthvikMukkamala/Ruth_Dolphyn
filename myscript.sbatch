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

PROJECTDIR="/home/rcm8412/DOLPHYN"

julia --project=$PROJECTDIR -e '
    using Pkg;
    Pkg.add("Gurobi");
    Pkg.build("Gurobi");
    Pkg.add("Dolphyn");
    Pkg.instantiate();
    cd("/home/rcm8412/DOLPHYN/Example_Systems/SmallNewEngland/OneZone");
    include("Run.jl");
'