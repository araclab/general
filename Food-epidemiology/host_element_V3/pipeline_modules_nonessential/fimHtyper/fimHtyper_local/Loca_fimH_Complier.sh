#!/bin/bash
#SBATCH --time 30:00
#SBATCH -p nano
#SBATCH -o Slurm_Array_Compiler_%j.out
#SBATCH -e Slurm_Array_Compiler_%j.err

# Created by Edward Sung (edward.sung@gwu.edu) on 2/25/2024


STARTTIMER="$(date +%s)"


# Conda Enviroment - Please change to load your conda environment
# . /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
# conda activate your_enviroment


# Modules - Please add any modules required
# module load (module)


# Script and Tool Locations - Include any additional script path as needed
Slurm_Array_scripts="/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules_nonessential/fimHtyper/fimHtyper_local"


# Inputs
main_output_folder_input=$1


mkdir $main_output_folder_input/compiled_files


# Create a file to store youre results -- this is just an example of a method to compile results
echo -e "sampleID\tfimHtype" > $main_output_folder_input/compiled_files/results_compiled.txt


# Create a list of your output folders
ls $main_output_folder_input/processing_files > tmplist_output_folders


# Loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   tab_file=$main_output_folder_input/processing_files/${line}/results_tab.txt
   if grep -q "$line" "$tab_file"; then
      fimh_type=$(grep "$line" "$tab_file" | awk -F'\t' 'NR==1 {print $1}')
   else
      fimh_type="None_Found"
   fi
   echo -e "${line}\t${fimh_type}" >> $main_output_folder_input/compiled_files/results_compiled.txt
done < tmplist_output_folders


# Clean-up file system
rm tmplist_output_folders


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
