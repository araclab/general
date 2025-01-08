#!/bin/sh


# To Run: bash kmodes_submitter.sh (data_tsv) (output_name)

# Script and Tool PATHS
kmodes_scripts="/YOUR/FILE/PATH/HERE/kmodes/scripts"


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
