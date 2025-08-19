#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p tiny,small-gpu,debug
#SBATCH -e host_element_pipeline_%j.err
#SBATCH -o host_element_pipeline_%j.out


# Updated Version: 	v4.0
# Updated By:		Edward Sung (edward.sung@gwu.edu)
# Updated Date: 	05/27/25


STARTTIMER="$(date +%s)"

# Environments, Modules, Exports, Variables
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh


# pegasus modules
module load perl5


# paths
element_genes_screen="/scratch/liu_price_lab/ehsung/github/Development/ehsung/Food-epidemiology/host_element_pipeline/databases/20250527_elementgeneList.fasta"

host_element_scipts="/scratch/liu_price_lab/ehsung/github/Development/ehsung/Food-epidemiology/host_element_pipeline/scripts"
helper_scripts="/scratch/liu_price_lab/ehsung/github/Development/ehsung/Food-epidemiology/host_element_pipeline/scripts/helper_scripts"
mmseq2_scripts="/scratch/liu_price_lab/ehsung/github/Development/ehsung/microbiome/mmseq2/scripts"






# User Inputs
Data_Folder_input=$1
Data_Folder_Samplelist_input=$2
Data_Folder_Hostlist_input=$3
Job_Name_input=$4






# Error for required number of inputs
if [ $# -lt 4 ]
then
	echo "Please give all 4 arugments (Data_Folder_input) (Data_Folder_Samplelist_input) (Data_Folder_Hostlist_input) (Job_Name_input)"
        exit 1
fi


# Create main output folder
mkdir ${Job_Name_input}_output
mkdir ${Job_Name_input}_output/processing_files
mkdir ${Job_Name_input}_output/slurmFiles



echo "-------------------- STEP 1. Submitted MMSEQ2 Genes Screening Jobs --------------------"

# Create file system for mmseq2 files
mkdir ${Job_Name_input}_output/processing_files/mmseq2_screening
mmseq2_screening_folder="${Job_Name_input}_output/processing_files/mmseq2_screening"

mkdir $mmseq2_screening_folder/rawData_500bpTrimmed


# Trim the scaffolds input at 500 bp threshold (No scaffolds less than 500 bp)
while read -r fasta_file
do
   # Get base filename
   filename="${fasta_file%%.*}"

   # Use helper script to remove 500 bp or less contigs
   perl $helper_scripts/removesmalls.pl 500 $Data_Folder_input/$fasta_file > $mmseq2_screening_folder/rawData_500bpTrimmed/${filename}-500bpTrimmed.fasta
done < $Data_Folder_Samplelist_input


# Run mmseq2 on the 500bpTrimmed data
ls $mmseq2_screening_folder/rawData_500bpTrimmed > $mmseq2_screening_folder/${Job_Name_input}_mmseq2_samplelist.txt

bash $mmseq2_scripts/mmseq2_Submitter.sh $mmseq2_screening_folder/rawData_500bpTrimmed $mmseq2_screening_folder/${Job_Name_input}_mmseq2_samplelist.txt $element_genes_screen nucl 0.8 0.8 ${Job_Name_input}_mmseq2



echo "-------------------- STEP 2. Submitted Host Element Caller Compiler Job, Waits on completion of MMSEQ2 Screening --------------------"

sbatch --dependency=singleton -J ${Job_Name_input}_mmseq2 $host_element_scipts/host_element_pipeline_Element_Caller.sh ${Job_Name_input}_mmseq2 ${Job_Name_input}_output $Data_Folder_Hostlist_input $element_genes_screen $Job_Name_input



echo "-------------------- STEP 3. Cleaning Up Files and Folders --------------------"
mv host_element_pipeline_${SLURM_JOB_ID}.err ${Job_Name_input}_output/slurmFiles
mv host_element_pipeline_${SLURM_JOB_ID}.out ${Job_Name_input}_output/slurmFiles




# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
