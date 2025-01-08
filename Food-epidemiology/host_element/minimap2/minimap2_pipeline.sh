#!/bin/sh
#SBATCH --time 7-00:00:00
#SBATCH -p highThru
#SBATCH -o minimap2_%j.out
#SBATCH -e minimap2_%j.err

# Minimap2 Pipeline performs minimap2 using asm20 threshold with one sbatch submission on all files in a reference folder against a single fasta file containing target sequences.
# The .paf files are then processed by the minimap2_output_processor.py script to output summary tables and element_prevalence tables.
# .maf and .fasta files are also created for the aligned sequences.

# Updated to v2.0
# Edward Sung (edward.sung@gwu.edu) on 2/23/23

# Created by Edward Sung (edward.sung@gwu.edu) on 11/03/22

STARTTIMER="$(date +%s)"

# Environments, Modules, Exports
. /YOUR/CONDA/PATH/HERE/conda.sh

# HPC Modules (can be replaced with local installation)
module load minimap2/2.24
module load perl5


export target_element_genes='/YOUR/FILE/PATH/HERE/databases/'
export python_scripts='/YOUR/FILE/PATH/HERE/python/'
export perl_scripts='/YOUR/FILE/PATH/HERE/perl/'

element_genes_fastaFile=20221101_elementgeneList.fasta

# User Inputs
reference_fasta_folder=$1 #Currently only .fasta files
reference_fasta_HostLabels=$2
output_naming=$3 #Please include date for output

# Error for required number of inputs
if [ $# -lt 3 ]
then
        echo "Please give all 3 arugments (reference_fasta_folder), (reference_fasta_HostLabels), and (output_name)"
        exit 1
fi


# Create main output folder
main_output=${output_naming}_minimap2_output_folder
mkdir $main_output


echo "-------------------- STEP 1. Starting Minimap2 Processing --------------------"

# Create Output Folder for minimap2 .paf files
mkdir $main_output/minimap2_paf_files
mkdir $main_output/rawData_500bpTrimmed
mkdir $main_output/minimap2_paf_files/0_minimap2_maf_files
mkdir $main_output/minimap2_paf_files/1_minimap2_fasta_files


# Perform Minimap2
echo "minimap2 -cx asm20 --cs=long"

for i in $reference_fasta_folder/*.fasta 
   do
      echo "Performing Minimap2 on: $i"

      # Remove the suffix ".fasta" for naming files
      file_name=${i%.fasta}

      # Remove contigs that are less than 500 bp
      perl $perl_scripts/removesmalls.pl 500 $i > ${file_name##*/}-500bpTrimmed.fasta
 
      minimap2 -cx asm20 --cs=long ${file_name##*/}-500bpTrimmed.fasta $target_element_genes/$element_genes_fastaFile > $main_output/minimap2_paf_files/${file_name##*/}-asm20.paf
      
      # Create the maf file, grep "s" is to select only the sequences
      paftools.js view -f maf $main_output/minimap2_paf_files/${file_name##*/}-asm20.paf > $main_output/minimap2_paf_files/0_minimap2_maf_files/${file_name##*/}-asm20.maf
      
      # Create the fasta file for the alignment based on maf file
      grep "s" $main_output/minimap2_paf_files/0_minimap2_maf_files/${file_name##*/}-asm20.maf | awk '{print $2}' | tail -n +2 | sed 'N;s/\n/__/' |  sed "s/^/${file_name##*/}__/g" > tmpfile1
      grep "s" $main_output/minimap2_paf_files/0_minimap2_maf_files/${file_name##*/}-asm20.maf | awk '{print $7}' | sed -n '1~2!p' | tr '[a-z]' '[A-Z]' | sed 's/-//g' > tmpfile2

      while IFS= read -r line1 && IFS= read -r line2 <&3
         do
            printf '>'${line1}'\n' >> $main_output/minimap2_paf_files/1_minimap2_fasta_files/${file_name##*/}-asm20.fasta
            printf $line2'\n' >> $main_output/minimap2_paf_files/1_minimap2_fasta_files/${file_name##*/}-asm20.fasta
         done < tmpfile1 3< tmpfile2
      
      
      mv ${file_name##*/}-500bpTrimmed.fasta $main_output/rawData_500bpTrimmed
   done

rm tmpfile1
rm tmpfile2

# Create element_genes_fasta_NAMES for python script input
cat $target_element_genes/$element_genes_fastaFile | grep ">" > $main_output/element_genes_fasta_Names.txt

echo "-------------------- Completed minimap2 processing --------------------"


echo "-------------------- STEP 2. Starting Minimap2 Output Processing --------------------"
# Create Output Folder for python script processor
mkdir $main_output/minimap2_processed_files
mkdir $main_output/minimap2_processed_files/main_data
mkdir $main_output/minimap2_processed_files/element_presence
mkdir $main_output/minimap2_processed_files/blcm_ready

conda activate python3.8.1
# Inputs: paf_files, host_labels, element_gene_names, output_name
python $python_scripts/minimap2_output_processor.py $main_output/minimap2_paf_files/ $reference_fasta_HostLabels $main_output/element_genes_fasta_Names.txt $output_naming

echo "-------------------- Completed Minimap2 Output Processing --------------------"


echo "-------------------- Cleaning Up Files and Folders --------------------"


mv ${output_naming}_Main_Data.xlsx $main_output/minimap2_processed_files/main_data
mv ${output_naming}_Main_Data.tsv $main_output/minimap2_processed_files/main_data
mv ${output_naming}_filtered_Main_Data.tsv $main_output/minimap2_processed_files/main_data

mv ${output_naming}_*_element_presence.tsv $main_output/minimap2_processed_files/element_presence

# mv $reference_fasta_folder $main_output

mkdir $main_output/MiscFiles
mv $main_output/element_genes_fasta_Names.txt $main_output/MiscFiles
mv $reference_fasta_HostLabels $main_output/MiscFiles

mkdir $main_output/slurm_output_script
mv minimap2_*.out $main_output/slurm_output_script
mv minimap2_*.err $main_output/slurm_output_script
mv minimap2_pipeline.sh $main_output/slurm_output_script


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"

echo "-------------------- Minimap2 Completed, Thank You --------------------" 
