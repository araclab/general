#!/bin/sh
#SBATCH --time 3-00:00:00
#SBATCH --job-name=BLCM
#SBATCH -p project
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err
#SBATCH --cpus-per-task=4

STARTTIMER="$(date +%s)"

#paths
host_element_blcm_scripts="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/Jon_Proj/MODIFIED_general_clone_14112025/Food-epidemiology/host_element_v2/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026"
#conda envs
. /users/data/Tools/Conda/Miniconda3-py312_24.11.1-0-Linux-x86_64/etc/profile.d/conda.sh
conda activate jags 

# HPC Modules
module load R/4.1.1


# User Inputs
CSV_Input=$1
Folder_Output=$2

Rscript $host_element_blcm_scripts/hostelement_blca_kmodes_CLUST2_SSI_noBeefnTurkey_20260204.R -i $CSV_Input -o $Folder_Output


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
