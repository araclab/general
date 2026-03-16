#!/bin/sh


# To Run: bash kmodes_validation_submitter.sh (data_tsv) (cluster_k) (output_name)

# Script and Tool PATHS
kmodes_scripts="/lustre/groups/liu_price_lab/ehsung/2_GitHub/Development/ehsung/microbiome/kmodes/scripts/validations"


# User inputs
data_tsv_input=$1
cluster_k_input=$2
output_name_input=$3


# Create File System
mkdir ${output_name_input}_output
mkdir ${output_name_input}_output/compiled_results
mkdir slurmFiles
mkdir slurmFiles/scripts
mkdir slurmFiles/slurm_outputs

# Submit sbatches for set_numbers of 1 to 10
for set_number in {1..10}
do
   sbatch -J $output_name_input $kmodes_scripts/kmodes_validation_runner.sh $data_tsv_input $set_number $cluster_k_input $output_name_input ${output_name_input}_output
done

# Compile Results
sbatch --dependency=singleton -J $output_name_input $kmodes_scripts/kmodes_validation_compiler.sh ${output_name_input}_output $output_name_input
