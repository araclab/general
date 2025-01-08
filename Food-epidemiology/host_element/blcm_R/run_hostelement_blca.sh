#!/bin/sh
#SBATCH --time 3-00:00:00
#SBATCH -p defq
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err

STARTTIMER="$(date +%s)"

# Conda Env
. /YOUR/CONDA/PATH/HERE/conda.sh
conda activate jags 

# HPC Modules
module load R/4.1.1


# User Inputs
CSV_Input=$1
Folder_Output=$2

Rscript hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20240806.R -i $CSV_Input -o $Folder_Output


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
