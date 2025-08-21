#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p tiny,small-gpu,debug
#SBATCH -e host_element_pipeline_Element_Caller_%j.err
#SBATCH -o host_element_pipeline_Element_Caller_%j.out


STARTTIMER="$(date +%s)"

# Environments, Modules, Exports, Variables
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate python3.8.1



# paths
helper_scripts="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/host_element_pipeline/scripts/helper_scripts"


# Pipeline Inputs
mmseq2_output_name=$1
main_output_folder=$2
host_file=$3
element_gene_names_file=$4
output_name=$5


# Create file structure
mkdir $main_output_folder/compiled_files
mkdir $main_output_folder/compiled_files/slurmFiles


# Move the completed mmseq2 run into respective folder within the main output folder
mv ${mmseq2_output_name}_output $main_output_folder/processing_files/mmseq2_screening

# Run mmseq2 element caller
python $helper_scripts/host_element_screen_processor.py $main_output_folder/processing_files/mmseq2_screening/${mmseq2_output_name}_output/compiled_files/result_compiled/ $host_file $element_gene_names_file $output_name

# Clean-up files
mv ${output_name}_Main_Data.xlsx $main_output_folder/compiled_files
mv ${output_name}_element_presence.tsv $main_output_folder/compiled_files
mv host_element_pipeline_Element_Caller_${SLURM_JOB_ID}.err $main_output_folder/compiled_files/slurmFiles
mv host_element_pipeline_Element_Caller_${SLURM_JOB_ID}.out $main_output_folder/compiled_files/slurmFiles


# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600))
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
