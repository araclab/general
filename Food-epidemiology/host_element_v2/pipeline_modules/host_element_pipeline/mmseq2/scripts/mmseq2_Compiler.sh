#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p debug,tiny,small-gpu,med-gpu
#SBATCH -o mmseq2_Compiler_%j.out
#SBATCH -e mmseq2_Compiler_%j.err

# -p tiny,small-gpu,debug

STARTTIMER="$(date +%s)"


# Conda Enviroment - Please change to load your conda environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh


# Script and Tool Locations - Include any additional script path as needed
Slurm_Array_scripts="/scratch/liu_price_lab/ehsung/github/Development/ehsung/microbiome/mmseq2/scripts"


# Inputs
main_output_folder_input=$1
reference_input=$2
jobname_input=$3


# Create file system
mkdir $main_output_folder_input/compiled_files
mkdir $main_output_folder_input/compiled_files/result_compiled
mkdir $main_output_folder_input/compiled_files/result_presence_absence
mkdir $main_output_folder_input/compiled_files/slurmFiles


# Create files to store youre results
echo -e "Query_Seq-id\tSubject_Seq-id\tPercent_Identity\tQuery_Coverage\tSubject_Coverage\tAlignment_Length\tMismatches\tGapOpenings\tQuery_Length\tQuery_Start\tQuery_End\tSubject_Length\tSubject_Start\tSubject_End\tE-Value\tBitscore\tCigar\tGenomeName" > $main_output_folder_input/compiled_files/${jobname_input}_mmseq2_result_compiled.tsv

echo -e "GenomeName\t$(grep "^>" $reference_input | sed 's/>//' | paste -s -d '\t')" > $main_output_folder_input/compiled_files/${jobname_input}_mmseq2_result_presence_absence.tsv


# Create a list of your output folders
ls $main_output_folder_input/processing_files > tmplist_output_folders


# Loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   tail -n +2 $main_output_folder_input/processing_files/$line/${line}_mmseq2_result_compiled.tsv >> $main_output_folder_input/compiled_files/${jobname_input}_mmseq2_result_compiled.tsv

   tail -n +2 $main_output_folder_input/processing_files/$line/${line}_mmseq2_result_presence_absence.tsv >> $main_output_folder_input/compiled_files/${jobname_input}_mmseq2_result_presence_absence.tsv

   cp $main_output_folder_input/processing_files/$line/${line}_mmseq2_result_compiled.tsv $main_output_folder_input/compiled_files/result_compiled
   cp $main_output_folder_input/processing_files/$line/${line}_mmseq2_result_presence_absence.tsv $main_output_folder_input/compiled_files/result_presence_absence

done < tmplist_output_folders


# Clean-up file system
rm tmplist_output_folders
mv mmseq2_Compiler_${SLURM_JOB_ID}.out $main_output_folder_input/compiled_files/slurmFiles
mv mmseq2_Compiler_${SLURM_JOB_ID}.err $main_output_folder_input/compiled_files/slurmFiles


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
