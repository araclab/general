#!/bin/bash
#SBATCH --time 24:00:00
#SBATCH -p project
#SBATCH -e mlstfinder_%j.err
#SBATCH -o mlstfinder_%j.out
#SBATCH -J mlstfinder
#SBATCH -c 4
#SBATCH --mem=8G

#Note: Remember to actiavte conda environment

#MLST (Multi-Locus Sequence Typing) is a method that identifies bacteria by sequencing a small set of housekeeping genes and assigning a unique “sequence type” (ST) based on their allele combinations.
#Housekeeping gene: essential genes that are always active and changes very slowly, such as genes that code metabolism

#conda
. /users/data/Tools/Conda/Miniconda3-py312_24.11.1-0-Linux-x86_64/etc/profile.d/conda.sh
conda activate araclab_blcm_mlst_dependencies

#input and output
input_folder=$1
output_folder=$2
sample_list=$3 #.txt file with samples that mlst should be run on

#create folder
mkdir -P $output_folder

#mlst location
mlst_loc="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/dependencies_and_databases_for_araclab_host_element_v2/tseemann_mlst/bin"

#loop through inputfolder to run mlst on each input file
for line in $(cat $sample_list);
do 
    #removing fasta extention
    name=$(echo $line | sed "s/.fasta//")
    #running mlst on file and adding it to the output folder
    $mlst_loc/mlst $input_folder/$line > $output_folder/${name}_mlst.csv
    cat "$output_folder"/${name}_mlst.csv >> "$output_folder"/concatenated_mlst.csv
    echo "processed $line"
    # sbatch -c 2 --mem=4G -J mlst -p project --wrap="$cmd"
    #echo $cmd
done
