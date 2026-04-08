#!/bin/sh
#SBATCH --time 8:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -p project
#SBATCH -e host_element_pipeline_%j.err
#SBATCH -o host_element_pipeline_%j.out

# Updated Version: 	v4.0.2
# Updated By:		Jon Slotved (JOSS@ssi.dk)
# Updated Date: 	03/23/26


STARTTIMER="$(date +%s)"

#config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
config_file="$PROJECT_DIR/config/config.env"

#activate conda
#source
conda_source=$(grep '^GLOBAL__CONDA_SH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
conda_env=$(grep '^HEP__CONDA_ENV__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
. "$conda_source"
conda activate "$conda_env"

project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
element_genes_screen="$project_root/pipeline_modules/host_element_pipeline/databases/20250818_elementgeneList.fasta"
host_element_scipts="$project_root/pipeline_modules/host_element_pipeline/scripts"
helper_scripts="$project_root/pipeline_modules/host_element_pipeline/scripts/helper_scripts"
mmseq2_scripts="$project_root/pipeline_modules/host_element_pipeline/mmseq2/scripts"

# User Inputs
Data_Folder_input=$1
Data_Folder_Samplelist_input=$2
Data_Folder_Hostlist_input=$3
Job_Name_input=$4
partition=${5:-project}
dependency=${6:-}

dep_flag=""
if [ -n "$dependency" ]; then
    dep_flag="--dependency=afterok:${dependency}"
fi

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

bash $mmseq2_scripts/mmseq2_Submitter.sh $mmseq2_screening_folder/rawData_500bpTrimmed $mmseq2_screening_folder/${Job_Name_input}_mmseq2_samplelist.txt $element_genes_screen nucl 0.8 0.8 ${Job_Name_input}_mmseq2 $partition "$dependency"



echo "-------------------- STEP 2. Submitted Host Element Caller Compiler Job, Waits on completion of MMSEQ2 Screening --------------------"

caller_jid=$(sbatch --parsable -p $partition --dependency=singleton -J ${Job_Name_input}_mmseq2 $host_element_scipts/host_element_pipeline_Element_Caller.sh ${Job_Name_input}_mmseq2 ${Job_Name_input}_output $Data_Folder_Hostlist_input $element_genes_screen $Job_Name_input)



echo "-------------------- STEP 3. Cleaning Up Files and Folders --------------------"
if [ -n "$SLURM_JOB_ID" ]; then
   mv host_element_pipeline_${SLURM_JOB_ID}.err ${Job_Name_input}_output/slurmFiles
   mv host_element_pipeline_${SLURM_JOB_ID}.out ${Job_Name_input}_output/slurmFiles
fi





# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))
echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
echo "$caller_jid"