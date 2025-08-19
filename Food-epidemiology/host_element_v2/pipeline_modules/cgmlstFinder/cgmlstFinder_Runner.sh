#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p nano
#SBATCH -e cgmlstFinder_Runner_%A_%a.err
#SBATCH -o cgmlstFinder_Runner_%A_%a.out


# Main script to run the cgmlstfinder, modified for the md5sum return
# Note: this script focuses and uses the on the ecoli database


# Script Developed by: Edward Sung (edward.sung@gwu.edu) on 02/20/24


STARTTIMER="$(date +%s)"


# Conda Environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh

# cge_tools_env can be created from scratch by just installing the necessary tools to run cgmlstfinder: https://bitbucket.org/genomicepidemiology/cgmlstfinder/src/master/
conda activate cge_tools_env


# Script and Tools Paths
CGE_DB_Path="/GWSPH/groups/liu_price_lab/pegasus_bin/Tools/CGE_tools/cgmlstfinder_db" # Obtained from https://bitbucket.org/genomicepidemiology/cgmlstfinder_db/src/master/
CGE_KMA_Tool_Path="/GWSPH/groups/liu_price_lab/pegasus_bin/Tools/CGE_tools/kma/kma"
CGE_Tool_Path="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/cgmlstFinder/cgMLSTFinder_git/" # Git clone repo under pipeline_modules/cgmlstFinder



# User Input
Data_Folder_input=$1
Data_Folder_Samplelist_SLURM_ARRAY_READY_input=$2
Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input=$3
main_output_folder_input=$4



# Obtains the filename indicated by slurm_array_id
fileInput="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $3}')"

# Remove extensions to just get filename
filename=${fileInput%.*}


# Create sample folder for outputs
mkdir $main_output_folder_input/processing_files/$filename
mkdir $main_output_folder_input/processing_files/$filename/slurm_outputs


# Run cgmlstfinder
echo "Performing cgmlstfinder on: $fileInput"
$CGE_Tool_Path/cgMLST_EHS_Modified.py -i ${Data_Folder_input}/$fileInput -s ecoli -db $CGE_DB_Path -k $CGE_KMA_Tool_Path -o $main_output_folder_input/processing_files/$filename

# Convert all results to md5
echo Run cgmlstfinder md5 converter
$CGE_Tool_Path/CGE_cgMLST_md5_converter.py $main_output_folder_input/processing_files/$filename ecoli_results.txt kma_${filename}.fsa


# Clean-up File System
mv cgmlstFinder_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err $main_output_folder_input/processing_files/$filename/slurm_outputs
mv cgmlstFinder_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out $main_output_folder_input/processing_files/$filename/slurm_outputs


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600)) 
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
