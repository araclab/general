#!/bin/sh
# Script Developed by: Maliha Aziz (araclab@gwu.edu) on 03/23/26

# How to Submit jobs:
# bash cgmlstFinder_nonHPC.sh (Data_Folder_input) (Data_Folder_Samplelist_input)
	# Fasta_Folder_input -- folder containings all of the fasta assemblies
	# Output_folder_name -- Output folder name


STARTTIMER="$(date +%s)"
# Script and Tools Paths
CGE_DB_Path="/PATH TO CGMLST DIR/cgmlstfinder_db" # Obtained from https://bitbucket.org/genomicepidemiology/cgmlstfinder_db/src/master/
CGE_KMA_Tool_Path="/PATH TO KMA DIR/kma"
CGE_Tool_Path="/github/Food-epidemiology/host_element_v2/pipeline_modules/cgmlstFinder/cgMLSTFinder_git" # Git clone repo under pipeline_modules/cgmlstFinder
cgmlstfinder_scripts="/github/Food-epidemiology/host_element_v2/pipeline_modules/cgmlstFinder"

# User Inputs
Data_Folder_input=$1
Out_folder_name=$2


# Error for required number of inputs
if [ $# -lt 2 ]
then
    echo "Please give all 2 arugments: (Fasta_Folder_input) (Out_folder_name)"
   exit 1
fi

mkdir ${Out_folder_name}
cd ${Out_folder_name}
cp $cgmlstfinder_scripts/kmodes_ready_inputfile_TEMPLATE.txt kmodes_ready_inputfile.txt

for filepath in "$Data_Folder_input"/*.*; do
    fileInput=$(basename "$filepath")
    filename="${fileInput%%.*}"
    echo "$filename"
    mkdir $filename
    # Run cgmlstfinder
    echo "Performing cgmlstfinder on: $fileInput"
    $CGE_Tool_Path/cgMLST_EHS_Modified.py -i ${Data_Folder_input}/$fileInput -s ecoli -db $CGE_DB_Path -k $CGE_KMA_Tool_Path -o $filename

    # Convert all results to md5
    echo Run cgmlstfinder md5 converter
    $CGE_Tool_Path/CGE_cgMLST_md5_converter.py $filename ecoli_results.txt kma_${filename}.fsa
    echo "Extracting cgmlst md5 results into kmodes_ready_inputfile: $line"
    cat $filename/ecoli_results_md5_conversion.txt | tail -n +2  >> kmodes_ready_inputfile.txt
done
