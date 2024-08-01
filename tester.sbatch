#!/bin/bash

#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=4GB
#SBATCH --job-name=TEST_ANNUAL_RPS
#SBATCH --mail-type=END
#SBATCH --mail-user=ruthvikmukkamala@nyu.edu
#SBATCH --output=slurm_%j.out

# Environment setup
PROJECTDIR="/home/rcm8412/Dolphyn.jl"
EXT3_PATH="/ext3"
JULIA_PATH="$EXT3_PATH/julia-1.10.4"



singularity exec \
  --bind /home/rcm8412/julia-1.10.0/compiled:/ext3/pkgs/compiled \
  --bind /home/rcm8412/julia-1.10.0/logs:/ext3/pkgs/logs  \
  --overlay /home/rcm8412/julia-1.10.0/julia-1.10.0.ext3:rw  \
  /scratch/work/public/singularity/ubuntu-20.04.4.sif \
  /bin/bash
