#!/bin/sh
#SBATCH --time 02:00:00
#SBATCH -p project
#SBATCH -e cgmlstFinder_Runner_%A_%a.err
#SBATCH -o cgmlstFinder_Runner_%A_%a.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=15G

# Main script to run the cgmlstfinder, modified for the md5sum return
# Note: this script focuses and uses the on the ecoli database


# Script Developed by: Edward Sung (edward.sung@gwu.edu) on 02/20/24
# Script Modified by: Jon Slotved (JOSS@dksund.dk)

STARTTIMER="$(date +%s)"

#config file:


# Input
Data_Folder_input=$1
Data_Folder_Samplelist_SLURM_ARRAY_READY_input=$2
Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input=$3
main_output_folder_input=$4
#config (defaults to local path)
config_file_local="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"
config_file=${5:-${config_file_local}}

# Conda Environment
# cge_tools_env can be created from scratch by just installing the necessary tools to run cgmlstfinder: https://bitbucket.org/genomicepidemiology/cgmlstfinder/src/master/
conda_source=$(cat "$config_file" | grep '^GLOBAL__CONDA_SH__=' | awk -F'__=' '{print $2}' | xargs)
conda_env=$(cat "$config_file" | grep '^CGE__CONDA_ENV__=' | awk -F'__=' '{print $2}' | xargs)
. "$conda_source"
conda activate "$conda_env"

echo "before"
set -x

# Script and Tools Paths
project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
CGE_DB_Path=$(grep '^CGE__DB_PATH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
CGE_KMA_Tool_Path=$(grep '^CGE__KMA_PATH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
CGE_Tool_Path="$project_root/pipeline_modules/cgmlstFinder/cgMLSTFinder_git"

# make sure paths exit
for path in "$CGE_DB_Path" "$CGE_KMA_Tool_Path" "$CGE_Tool_Path"; 
do
    if [ ! -d "$path" ] && [ ! -f "$path" ]; then
        echo "ERROR: Path not found or invalid: $path"
        exit 1
    fi
done


# Obtains the filename indicated by slurm_array_id
fileInput="$(cat $Data_Folder_Samplelist_SLURM_ARRAY_READY_input | grep "^${Data_Folder_Samplelist_SLURM_ARRAY_READY_index_set_input}__@__${SLURM_ARRAY_TASK_ID}__@__" | awk -F "__@__" '{print $3}')"

# Remove extensions to just get filename
filename=${fileInput%.*}


# Create sample folder for outputs
mkdir $main_output_folder_input/processing_files/$filename
mkdir $main_output_folder_input/processing_files/$filename/slurm_outputs



# Copy the entire ecoli database into this job's private folder
cp ${CGE_DB_Path}/ecoli/* $LOCAL_DB_DIR/ecoli/

# run cgmlstfinder with retry if KMA result file is missing or empty
echo "Performing cgmlstfinder on: $fileInput"


max_attempts=5
attempt=1
KMA_RES_FILE="$main_output_folder_input/processing_files/$filename/kma_${filename}.res"

while [ $attempt -le $max_attempts ] && [ ! -s "$KMA_RES_FILE" ]; do
    echo "Attempt $attempt: Running cgMLST_EHS_Modified.py"
    $CGE_Tool_Path/cgMLST_EHS_Modified.py -i "${Data_Folder_input}/$fileInput" -s ecoli -db "$CGE_DB_Path" -k "$CGE_KMA_Tool_Path" -o "$main_output_folder_input/processing_files/$filename"
    attempt=$((attempt + 1))
    sleep 2 #make sure file is not mid write, when retrying 
done

if [ ! -s "$KMA_RES_FILE" ]; then
    echo "ERROR: $KMA_RES_FILE missing or empty after $max_attempts attempts."
fi

if [ $success -ne 1 ]; then
    echo "ERROR: cgMLST_EHS_Modified.py failed after $max_attempts attempts or $KMA_RES_FILE missing/empty."
fi

# Convert all results to md5
echo Run cgmlstfinder md5 converter
$CGE_Tool_Path/CGE_cgMLST_md5_converter.py $main_output_folder_input/processing_files/$filename ecoli_results.txt kma_${filename}.fsa

# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600)) 
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"

# Clean-up File System
mv cgmlstFinder_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.err $main_output_folder_input/processing_files/$filename/slurm_outputs
mv cgmlstFinder_Runner_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out $main_output_folder_input/processing_files/$filename/slurm_outputs

set +x
echo "after"