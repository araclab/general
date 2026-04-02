#!/bin/bash
#SBATCH --time=2-00:00:00
#SBATCH -p project
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH -o blcm_analysis_%j.out
#SBATCH -e blcm_analysis_%j.err


#blcm pipeline wrapper, written by Jon Slotved on 02/04/2026
#please contact via: JOSS@dksund.dk

#config
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

#paths
project_root=$(grep "^GLOBAL__PROJECT_ROOT__=" "$config_file" | awk -F'__=' '{print $2}')

#how to use 
print_usage() {
	echo
    echo "Usage: sbatch/bash BLCM_analysis.sh <assembly_folder> <host_tsv> <output_directory> [partition]"
	echo
	echo "Arguments:"
	echo "  assembly_folder  Folder containing genome assemblies in fasta/fa/fna format"
	echo "  host_tsv         TSV file with two columns: sampleID and Host"
	echo "  output_directory Destination folder for intermediate and final outputs"
	echo "  partition        SLURM partition to use (optional, default: project)"
    echo
    echo "PLEASE NOTE: avoid unusual filenames with spaces, commas or dots"
	echo "It is also recommended that full paths are used when filling arguments"
    echo 
}

#get input
input_folder="$1"
host_info="$2"
main_output_folder="$3"
partition=${4:-project}

#check input and print_usage if bad
if [ -z "$input_folder" ] || [ -z "$host_info" ] || [ -z "$main_output_folder" ]; then
    print_usage
	echo
	echo "found information:"
	echo "input_folder: ${input_folder}"
	echo "host_info: ${host_info}"
	echo "output_loc: ${main_output_folder}"
	echo "partition: ${partition}"
    exit 1
fi

#create file system
mkdir -p "$main_output_folder"/tmp_analysis
cat "$host_info" | awk -F'\t' '{print $1}' | sed 's/$/\.fasta/' | tail -n +2 > "$main_output_folder"/tmp_analysis/sample_list.txt


#run modules


#compile results