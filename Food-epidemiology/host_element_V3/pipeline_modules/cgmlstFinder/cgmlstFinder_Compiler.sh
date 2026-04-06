#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -o cgmlstFinder_Compiler_%j.out
#SBATCH -e cgmlstFinder_Compiler_%j.err


# This script runs at the end of cgmlstfinder, where it compiles the results into kmode_ready file.
# It is automatically queued up by the cgmlstFinder module.
# It also cleans up the remaining file system.

#config file:
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

#get path to main script loc
project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
cgmlstfinder_scripts="$project_root/pipeline_modules/cgmlstFinder"


# Inputs
main_output_folder_input=$1
jobname_input=$2
slurm_array_ready_file=$3

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

# Post-compile checks
expected_samples=$(wc -l < tmpfilelist)
compiled_rows=$(tail -n +2 "$main_output_folder_input/compiled_files/${jobname_input}_kmodes_ready_inputfile.txt" | wc -l)
if [ "$compiled_rows" -ne "$expected_samples" ]; then
   echo "WARNING: compiled kmodes file has $compiled_rows rows but expected $expected_samples (one per sample)"
fi

missing=0
while read -r sample; do
   if [ ! -f "$main_output_folder_input/processing_files/$sample/ecoli_results_md5_conversion.txt" ]; then
      echo "WARNING: missing results for sample: $sample"
      missing=$((missing + 1))
   fi
done < tmpfilelist
if [ "$missing" -gt 0 ]; then
   echo "WARNING: $missing sample(s) are missing results in compiled output"
fi

# Cleanup file system
rm tmpfilelist

mkdir $main_output_folder_input/compiled_files/slurm_files
mv cgmlstFinder_Compiler_${SLURM_JOB_ID}.out $main_output_folder_input/compiled_files/slurm_files
mv cgmlstFinder_Compiler_${SLURM_JOB_ID}.err $main_output_folder_input/compiled_files/slurm_files
mv "$slurm_array_ready_file" $main_output_folder_input
