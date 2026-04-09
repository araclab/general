#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -e Slurm_Array_Runner_%A_%a.err
#SBATCH -o Slurm_Array_Runner_%A_%a.out


#created by Jon Slotved (JOSS@dksund.dk)

STARTTIMER="$(date +%s)"

# User Input
Data_Folder_input=$1
Data_Folder_Samplelist_SLURM_ARRAY_READY_input=$2
Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input=$3
main_output_folder_input=$4

# Config file as last argument
config_file_local="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"
config_file=${5:-${config_file_local}}

# Conda Enviroment - Please change to load your conda environment
conda_source=$(grep "^GLOBAL__CONDA_SH__=" "$config_file" | awk -F'__=' '{print $2}')
conda_env=$(grep "^MLST__CONDA_ENV__=" "$config_file" | awk -F'__=' '{print $2}')
. "$conda_source"
conda activate "$conda_env"


# Script and Tool Locations - Include any additional script path as needed
mlst=$(grep "^MLST__EXECUTABLE__=" "$config_file" | awk -F'__=' '{print $2}')



# Obtains the filename indicated by slurm_array_id
fileInput="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $3}')"


# Remove extensions to just get filename
filename=${fileInput%.*}


# Create sample folder for outputs
mkdir -p "$main_output_folder_input/processing_files/$filename"
mkdir -p "$main_output_folder_input/processing_files/$filename/slurm_outputs"
mkdir -p "$main_output_folder_input/processing_files/$filename/tmp"


# Run Tool command hers
echo "Performing mlst on: $fileInput"
"$mlst/mlst" --scheme ecoli_achtman_4 "$Data_Folder_input/$fileInput" > "$main_output_folder_input/processing_files/$filename/results_tab.txt"

# Clean-up File System
mv Slurm_Array_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err $main_output_folder_input/processing_files/$filename/slurm_outputs
mv Slurm_Array_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out $main_output_folder_input/processing_files/$filename/slurm_outputs


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
