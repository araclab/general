#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -o cgmlstFinder_Compiler_%j.out
#SBATCH -e cgmlstFinder_Compiler_%j.err


# This script runs at the end of cgmlstfinder, where it compiles the results into kmode_ready file.
# It is automatically queued up by the cgmlstFinder module.
# It also cleans up the remaining file system.

#config file:
config_file="config/minifig.txt"

#get path to main script loc
cgmlstfinder_scripts=$(cat $config_file | grep __cgmlstfinder_scripts__@__ | awk -F'__:' '{print $2}' | xargs)


# Inputs
main_output_folder_input=$1
jobname_input=$2


#compile the results into this folder
mkdir $main_output_folder_input/compiled_files
cp $cgmlstfinder_scripts/kmodes_ready_inputfile_TEMPLATE.txt $main_output_folder_input/compiled_files/${jobname_input}_kmodes_ready_inputfile.txt


# Obtain sample_list with completed folder outputs
ls $main_output_folder_input/processing_files > tmpfilelist


# Compile the results into kmodes_ready_inputfile.txt
while read -r line
do
   echo "Extracting cgmlst md5 results into kmodes_ready_inputfile: $line"
   cat $main_output_folder_input/processing_files/$line/ecoli_results_md5_conversion.txt | tail -n +2  >> $main_output_folder_input/compiled_files/${jobname_input}_kmodes_ready_inputfile.txt
done < tmpfilelist

# Cleanup file system
rm tmpfilelist

mkdir $main_output_folder_input/compiled_files/slurm_files
mv cgmlstFinder_Compiler_${SLURM_JOB_ID}.out $main_output_folder_input/compiled_files/slurm_files
mv cgmlstFinder_Compiler_${SLURM_JOB_ID}.err $main_output_folder_input/compiled_files/slurm_files
