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

# Inputs
main_output_folder_input=$1

mkdir -p "$main_output_folder_input/compiled_files"


# Create a file to store youre results -- this is just an example of a method to compile results
echo -e "sampleID\tfimHtype" > $main_output_folder_input/compiled_files/results_compiled.txt


# Create a list of your output folders
ls $main_output_folder_input/processing_files > $main_output_folder_input/tmplist_output_folders
echo " deubg: $(ls $main_output_folder_input/tmplist_output_folders | wc -l)"

#loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   tab_file=$main_output_folder_input/processing_files/${line}/results_tab.txt
   if [ ! -f "$tab_file" ]; 
   then
      fimh_type="None_Found"
   else
      fimh_type=$(grep "^FimH type:" "$tab_file" | awk '{print $3}')
      if [ -z "$fimh_type" ]; 
      then
         fimh_type="None_Found"
      fi
   fi
   echo -e "${line}\t${fimh_type}" >> $main_output_folder_input/compiled_files/results_compiled.txt
done < "$main_output_folder_input/tmplist_output_folders"


# Clean-up file system
rm $main_output_folder_input/tmplist_output_folders
mkdir -p "$main_output_folder_input/compiled_files/slurm_files"
mv Slurm_Array_Compiler_${SLURM_JOB_ID}.out $main_output_folder_input/compiled_files/slurm_files
mv Slurm_Array_Compiler_${SLURM_JOB_ID}.err $main_output_folder_input/compiled_files/slurm_files
mv "$main_output_folder_input"/*_SLURM-ARRAY-READY.txt "$main_output_folder_input/compiled_files/"

# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
