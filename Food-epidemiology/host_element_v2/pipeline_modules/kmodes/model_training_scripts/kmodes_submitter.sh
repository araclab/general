#!/bin/sh


# To Run: bash kmodes_submitter.sh (data_tsv) (output_name)

# Script and Tool PATHS
kmodes_scripts="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/kmodes/model_training_scripts"


# User inputs
data_tsv_input=$1
output_name_input=$2


# Create File System
mkdir ${output_name_input}_output
mkdir ${output_name_input}_output/compiled_results
mkdir slurmFiles
mkdir slurmFiles/scripts
mkdir slurmFiles/slurm_outputs

# Submit sbatches for clusters_k of 2 to 8
for cluster_k in {2..8}
do
   sbatch -J $output_name_input $kmodes_scripts/kmodes_runner.sh $data_tsv_input $cluster_k $output_name_input ${output_name_input}_output
done

# Compile Results
sbatch --dependency=singleton -J $output_name_input $kmodes_scripts/kmodes_clustering_compiler.sh ${output_name_input}_output $output_name_input
