#!/bin/sh
#SBATCH --time 14-00:00:00
#SBATCH -p 384gb
#SBATCH -o kmodes_validations_%j.out
#SBATCH -e kmodes_validations_%j.err

STARTTIMER="$(date +%s)"


# Conda Environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate sklearn-env


# Script and Tool PATHS
kmodes_scripts="/lustre/groups/liu_price_lab/ehsung/2_GitHub/Development/ehsung/microbiome/kmodes/scripts/validations"


data_tsv_input=$1
set_number_input=$2
cluster_k_input=$3
output_name_input=$4
main_output_folder=$5


# Create File System
sample_folder="SetNumber_${set_number_input}"
mkdir $main_output_folder/$sample_folder
mkdir $main_output_folder/$sample_folder/slurm_outputs


# Run Kmodes modeling
python $kmodes_scripts/kmodes_clustering_validations.py $data_tsv_input $set_number_input $cluster_k_input $output_name_input


# Clean-up file system
mv ${output_name_input}_SetNumber${set_number_input}_Cluster${cluster_k_input}_predictions_validation.csv $main_output_folder/$sample_folder
mv kmodes_validations_${SLURM_JOB_ID}.out $main_output_folder/$sample_folder/slurm_outputs
mv kmodes_validations_${SLURM_JOB_ID}.err $main_output_folder/$sample_folder/slurm_outputs


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
