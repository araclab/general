#!/bin/bash
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -o Slurm_Array_Compiler_%j.out
#SBATCH -e Slurm_Array_Compiler_%j.err

# Created by Edward Sung (edward.sung@gwu.edu) on 2/25/2024
#modified by Jon Slotved

STARTTIMER="$(date +%s)"


# Modules - Please add any modules required
# module load (module)

#config
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

# Script and Tool Locations - Include any additional script path as needed
Slurm_Array_scripts=$(grep "^MLST__SLURM_SCRIPTS__=" "$config_file" | awk -F'__=' '{print $2}')

# Inputs
main_output_folder_input=$1

mkdir -p "$main_output_folder_input/compiled_files"


# Create a file to store youre results -- this is just an example of a method to compile results
echo -e "sampleID\tMLST" > $main_output_folder_input/compiled_files/results_compiled.txt


# Create a list of your output folders
ls $main_output_folder_input/processing_files > tmplist_output_folders


# Loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   tab_file="$main_output_folder_input/processing_files/${line}/results_tab.txt"
   if [ ! -f "$tab_file" ]; then
      mlst_type="None_Found"
      # awk validation: Check if column 3 (ST) exists, is not empty, and not a dash
      # NR==1: Process first line only (header)
      # $3 != "" && $3 != "-": Ensure field 3 is populated and meaningful
      # {found=1}: If conditions pass, set flag
      # END{exit !found}: Exit with 0 (success) if found=1, exit with 1 (failure) if found=0
   elif awk -F'\t' 'NR==1 && $3 != "" && $3 != "-" {found=1} END{exit !found}' "$tab_file"; then
      # awk extraction: Print column 3 (ST value) from first line and exit
      mlst_type=$(awk -F'\t' 'NR==1 {print $3; exit}' "$tab_file")
   else
      mlst_type="None_Found"
   fi
   echo -e "${line}\t${mlst_type}" >> "$main_output_folder_input/compiled_files/results_compiled.txt"
done < "tmplist_output_folders"


# Clean-up file system
rm tmplist_output_folders
mkdir -p "$main_output_folder_input/compiled_files/slurm_files"
mv Slurm_Array_Compiler_${SLURM_JOB_ID}.out $main_output_folder_input/compiled_files/slurm_files
mv Slurm_Array_Compiler_${SLURM_JOB_ID}.err $main_output_folder_input/compiled_files/slurm_files
mv *_SLURM-ARRAY-READY.txt $main_output_folder_input

# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
