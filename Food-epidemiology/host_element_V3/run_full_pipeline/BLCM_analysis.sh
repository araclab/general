#!/bin/bash
#SBATCH --time=2-00:00:00
#SBATCH -p project
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH -o blcm_analysis_%j.out
#SBATCH -e blcm_analysis_%j.err


#blcm pipeline wrapper, written by Jon Slotved on 02/04/2026
#please contact via: JOSS@dksund.dk

#how to use 
print_usage() {
	echo
    echo "Usage: bash BLCM_analysis.sh -i <assembly_folder> -t <host_tsv> -o <output_directory>"
	echo
	echo "Options:"
	echo "  -i  Folder containing genome assemblies in fasta/fa/fna format"
	echo "  -t  TSV file with two columns: sampleID and Host"
	echo "  -o  Destination folder for intermediate and final outputs"
	echo "  -h  Show this help message"
    echo
    echo
    echo "PLEASE NOTE: avoid any unusual filenames, such as fasta files, with spaces, commas or dots"
    echo "They should only inc"
}
#get input
getopts "i:t:o:h"
#check input and print_usage if bad
if [ $# -lt 4 ];then
print_usage
fi

#handle input


#create file system

#run modules

#compile results