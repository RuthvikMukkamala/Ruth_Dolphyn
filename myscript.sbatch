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
module load julia/1.6.1

PROJECTDIR="/home/rcm8412/DOLPHYN"

julia --project=$PROJECTDIR -e "
    using Pkg;
    Pkg.activate("$PROJECTDIR");
    Pkg.instantiate();
    cd("/home/rcm8412/DOLPHYN/Example_Systems/SmallNewEngland/OneZone");
    include("Run.jl");
"




#RUNDIR="$PROJECTDIR/runs/run-${SLURM_JOB_ID/.*}"
#mkdir -p $RUNDIR
#
#cd $RUNDIR
#
#julia --project=$PROJECTDIR -e "
#    using Pkg;
#    Pkg.activate("$PROJECTDIR");
#    Pkg.instantiate();
#    cd("/home/rcm8412/DOLPHYN/Example_Systems/SmallNewEngland/OneZone");
#    include("Run.jl");
#"
