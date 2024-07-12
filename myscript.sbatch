#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=4GB
#SBATCH --job-name=Dolphyn_SmallNewEngland
#SBATCH --mail-type=END
#SBATCH --mail-user=your.email@example.com
#SBATCH --output=slurm_%j.out

module purge
module load julia/1.8.5  # Adjust version as needed

PROJECTDIR="/Users/ruthvikmukkamala/PycharmProjects/Dolphyn.jl"
RUNDIR="$PROJECTDIR/runs/run-${SLURM_JOB_ID/.*}"
mkdir -p $RUNDIR

cd $RUNDIR

julia --project=$PROJECTDIR -e '
    using Pkg;
    Pkg.activate(".");
    Pkg.instantiate();
    cd("Example_Systems/SmallNewEngland/OneZone");
    include("Run.jl");
'