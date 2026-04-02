#!/bin/sh
#SBATCH --time 3-00:00:00
#SBATCH -j BLCM
#SBATCH -p project
#SBATCH -o run_hostelement_blca_%j.out
#SBATCH -e run_hostelement_blca_%j.err
#SBATCH --cpus-per-task=4

STARTTIMER="$(date +%s)"

get_config_value() {
	config_key="$1"
	config_line=$(grep "^${config_key}=" "$config_file")

	if [ -z "$config_line" ]; then
		print_error_and_exit "Missing config key: ${config_key}"
	fi

	config_value=$(echo "$config_line" | awk -F'__=' '{print $2}')

	if [ -z "$config_value" ]; then
		print_error_and_exit "Empty config value for key: ${config_key}"
	fi

	echo "$config_value"
}

#config file
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
config_file="$script_dir/../../../config/config.env"


#paths
host_element_blcm_scripts=$(get_config_value "BLCM__SCRIPTS__")
#conda envs
conda_source=$(get_config_value "GLOBAL__CONDA_SH__")
conda_env=$(get_config_value "BLCM__CONDA_ENV__")

. "$conda_source"
conda activate "$conda_env"

# HPC Modules
module load R/4.1.1

# User Inputs
CSV_Input=$1
Folder_Output=$2

Rscript "$host_element_blcm_scripts/hostelement_blca_kmodes_CLUST2_SSI_noBeefnTurkey_20260204.R" -i "$CSV_Input" -o "$Folder_Output"

# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
