#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p nano
#SBATCH -o cgmlstfinder_%A_%a.out
#SBATCH -e cgmlstfinder_%A_%a.err

# This script is to run the cgmlstfinder in "parallel" using slurm job array.

# It is called by the run_rgi_CARD.sh.
# It utilizes the cgmlstFinder_runner.sh bash script.

# Developed by Edward (G37543428) on 2/20/24


cgmlstfinder_scripts="/YOUR/FILE/PATH/HERE/cgmlstFinder/"


# User Input
fasta_folder_input=$1
fasta_sampleList_SLURM_ARRAY_READY_input=$2
fasta_sampleList_index_set_input=$3

# Perform cgmlstfinder (cgmlstFinder_runner.sh)
echo "$cgmlstfinder_scripts/cgmlstFinder_runner.sh $fasta_folder_input $fasta_sampleList_SLURM_ARRAY_READY_input $fasta_sampleList_index_set_input $SLURM_ARRAY_JOB_ID $SLURM_ARRAY_TASK_ID"
$cgmlstfinder_scripts/cgmlstFinder_runner.sh $fasta_folder_input $fasta_sampleList_SLURM_ARRAY_READY_input $fasta_sampleList_index_set_input $SLURM_ARRAY_JOB_ID $SLURM_ARRAY_TASK_ID
