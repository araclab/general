#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p nano
#SBATCH -o cgmlstFinder_compile_%j.out
#SBATCH -e cgmlstFinder_compile_%j.err


# This script runs at the end of cgmlstfinder, where it compiles the results into kmode_ready file.
# It also cleans up the remaining file system.


# Inputs
output_Folder=$1
fasta_sampleList_input=$2
sampleList_filename=$3

# Obtain sample_list with completed folder outputs
ls $output_Folder | grep -v "kmodes_ready" > tmpfilelist

# Compile the results into kmodes_ready_inputfile.txt
while read -r line
do
   echo "Extracting cgmlst md5 results into kmodes_ready_inputfile: $line"
   cat $output_Folder/${line}/ecoli_results_md5_conversion.txt | tail -n +2  >> $output_Folder/kmodes_ready/kmodes_ready_inputfile.txt
done < tmpfilelist

# Cleanup file system
rm tmpfilelist
mv run_cgmlstFinder.sh slurmFiles/scripts
mv $fasta_sampleList_input slurmFiles/scripts
mv ${sampleList_filename}_SLURM-ARRAY-READY.txt slurmFiles/scripts
mv cgmlstFinder_compile_${SLURM_JOB_ID}.out slurmFiles/slurm_outputs
mv cgmlstFinder_compile_${SLURM_JOB_ID}.err slurmFiles/slurm_outputs
