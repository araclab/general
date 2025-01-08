#!/bin/sh

# Main script to run the cgmlstfinder, modified for the md5sum return

# Script Developed by: Edward Sung (edward.sung@gwu.edu) on 02/20/24


STARTTIMER="$(date +%s)"


# Conda Environment
. /YOUR/CONDA/PATH/HERE/conda.sh
conda activate cge_tools_env


# Script and Tools Paths
CGE_DB_Path="/YOUR/FILE/PATH/HERE/cgmlstfinder_db/"
CGE_Tool_Path="/YOUR/FILE/PATH/HERE/cgMLSTFinder_git/"



# User Inputs
fasta_folder_input=$1
fasta_sampleList_SLURM_ARRAY_READY_input=$2
fasta_sampleList_index_set_input=$3
fasta_file_slurmJOB_ID=$4
fasta_file_slurmTASK_ID=$5



# Obtains the file name indicated by slurm_array_id
fileInput="$(cat $fasta_sampleList_SLURM_ARRAY_READY_input | grep "^${fasta_sampleList_index_set_input}__@__${fasta_file_slurmTASK_ID}__@__" | awk -F "__@__" '{print $3}')"


filename=${fileInput%.*}
mkdir cgmlstfinder_output/$filename
mkdir cgmlstfinder_output/$filename/slurm_outputs

echo "fileInput: $fileInput"
echo "filename: $filename"

echo "Performing cgmlstfinder on: $fileInput"

echo Run cgmlstfinder
$CGE_Tool_Path/cgMLST_EHS_Modified.py -i ${fasta_folder_input}/$fileInput -s ecoli -db $CGE_DB_Path/cgmlstfinder_db -k $CGE_DB_Path/kma/kma -o cgmlstfinder_output/$filename

echo Run cgmlstfinder md5 converter
$CGE_Tool_Path/CGE_cgMLST_md5_converter.py cgmlstfinder_output/$filename/ ecoli_results.txt kma_${filename}.fsa


mv cgmlstfinder_${fasta_file_slurmJOB_ID}_${fasta_file_slurmTASK_ID}.err cgmlstfinder_output/$filename/slurm_outputs
mv cgmlstfinder_${fasta_file_slurmJOB_ID}_${fasta_file_slurmTASK_ID}.out cgmlstfinder_output/$filename/slurm_outputs


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600)) 
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
