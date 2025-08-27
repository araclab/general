#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p debug
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err

STARTTIMER="$(date +%s)"


host_element_blcm_scripts="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/host_element_blcm"


# Conda Env
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate jags 

# HPC Modules
module load R/4.1.1


# User Inputs
CSV_Input=$1
Folder_Output=$2

Rscript $host_element_blcm_scripts/hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20250818.R -i $CSV_Input -o $Folder_Output


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
