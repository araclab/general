#!/bin/sh
#SBATCH --time 3-00:00:00
#SBATCH -J BLCM
#SBATCH -p project
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err
#SBATCH --cpus-per-task=4

STARTTIMER="$(date +%s)"

#config file
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

#paths
project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}')
host_element_blcm_scripts="$project_root/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026"
#conda envs
conda_source=$(grep "^GLOBAL__CONDA_SH__=" "$config_file" | awk -F'__=' '{print $2}')
conda_env_blcm=$(grep "^BLCM__CONDA_ENV__=" "$config_file" | awk -F'__=' '{print $2}')
conda_env_r_basics=$(grep "^BLCM__R_BASICS_ENV__=" "$config_file" | awk -F'__=' '{print $2}')

. "$conda_source"

# HPC Modules
#module load R/4.1.1

# User Inputs
# $1: kmodes predictions CSV (output of kmodes_clustering_predicting.py)
# $2: HEP element presence TSV (output of host_element_pipeline)
# $3: Host TSV (two columns: sampleID and Host)
# $4: Output folder
kmodes_input=$1
elements_input=$2
host_tsv=$3
mlst_input=$4
Folder_Output=$5

if [ -z "$kmodes_input" ] || [ -z "$elements_input" ] || [ -z "$host_tsv" ] || [ -z "$Folder_Output" ] || [ -z "$mlst_input"]; then
    echo "Usage: sbatch run_hostelement_blca.sh <kmodes_predictions.csv> <element_presence.tsv> <host.tsv> <mlst.txt> <output_folder>"
    exit 1
fi

for check_file in "$kmodes_input" "$elements_input" "$host_tsv" "$mlst_input"; do
    if [ ! -f "$check_file" ]; then
        echo "ERROR: input file not found: $check_file"
        exit 1
    fi
done

mkdir -p "$Folder_Output"

sb27_base="$host_element_blcm_scripts/base_blcm_input/SB27_raw_input_26022026.csv"
blcm_input="$Folder_Output/final_blcm_input.csv"

# Step 1: compile blcm input (uses basic R env)
echo "--- Compiling BLCM input ---"
conda activate "$conda_env_r_basics"
Rscript "$host_element_blcm_scripts/compile_input.R" \
    -s "$sb27_base" \
    -k "$kmodes_input" \
    -e "$elements_input" \
    -t "$host_tsv" \
    -m "$mlst_input" \
    -o "$Folder_Output"

if [ ! -f "$blcm_input" ]; then
    echo "ERROR: compile_input.R did not produce final_blcm_input.csv"
    exit 1
fi

# Step 2: run BLCM (uses jags env)
echo "--- Running BLCM ---"
conda activate "$conda_env_blcm"
Rscript "$host_element_blcm_scripts/hostelement_blca_kmodes_CLUST2_SSI_noBeefnTurkey_20260204.R" -i "$blcm_input" -o "$Folder_Output"

# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
