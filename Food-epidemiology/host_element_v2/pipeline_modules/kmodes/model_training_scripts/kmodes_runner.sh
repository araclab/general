#!/bin/sh
#SBATCH --time 14-00:00:00
#SBATCH -p 384gb
#SBATCH -o kmodes_clustering_modeling_%j.out
#SBATCH -e kmodes_clustering_modeling_%j.err

STARTTIMER="$(date +%s)"


# Conda Environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate sklearn-env


# Script and Tool PATHS
kmodes_scripts="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/kmodes/model_training_scripts"






data_tsv_input=$1
cluster_k_input=$2
output_name_input=$3
main_output_folder=$4


# Create File System
sample_folder="cluster_${cluster_k_input}"
mkdir $main_output_folder/$sample_folder
mkdir $main_output_folder/$sample_folder/slurm_outputs


# Run Kmodes modeling
python $kmodes_scripts/kmodes_clustering_modeling.py $data_tsv_input $cluster_k_input $output_name_input


# Clean-up file system
mv ${output_name_input}_Cluster_${cluster_k_input}_model.pkl $main_output_folder/$sample_folder
mv ${output_name_input}_Cluster_${cluster_k_input}_clusters.csv $main_output_folder/$sample_folder
mv kmodes_clustering_modeling_${SLURM_JOB_ID}.out $main_output_folder/$sample_folder/slurm_outputs
mv kmodes_clustering_modeling_${SLURM_JOB_ID}.err $main_output_folder/$sample_folder/slurm_outputs


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
