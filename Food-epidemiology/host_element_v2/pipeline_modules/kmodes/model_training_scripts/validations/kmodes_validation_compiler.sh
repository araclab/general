#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p tiny
#SBATCH -o kmodes_validations_compiler_%j.out
#SBATCH -e kmodes_validations_compiler_%j.err


# Conda Environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate sklearn-env


# User Inputs
main_output_folder=$1
output_name_input=$2

# Create list of sample folders
ls $main_output_folder | grep -v "compiled_results"  > tmplist_output_folders


# Compile the silhouette scores
mkdir $main_output_folder/compiled_results/tmp_validationfiles
touch $main_output_folder/compiled_results/silhouette_score_compiled.txt


# Loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   cat $main_output_folder/${line}/slurm_outputs/*.out | grep "Silhouette Score" >> $main_output_folder/compiled_results/silhouette_score_compiled.txt
   cp $main_output_folder/${line}/*_predictions_validation.csv $main_output_folder/compiled_results/tmp_validationfiles
done < tmplist_output_folders

# Compile the clustering csv results
echo "Merging validation csv results"
csvjoin -c GenomeID $main_output_folder/compiled_results/tmp_validationfiles/*_predictions_validation.csv > $main_output_folder/compiled_results/${output_name_input}_predictions_validation.csv

# Temp Fix, csvjoin is treating 0 and 1, as false and true
sed -i 's/False/0/g' $main_output_folder/compiled_results/${output_name_input}_predictions_validation.csv
sed -i 's/True/1/g' $main_output_folder/compiled_results/${output_name_input}_predictions_validation.csv

# Clean-up File System
rm -r $main_output_folder/compiled_results/tmp_validationfiles
rm tmplist_output_folders
mv kmodes_validations_compiler_${SLURM_JOB_ID}.out slurmFiles/slurm_outputs
mv kmodes_validations_compiler_${SLURM_JOB_ID}.err slurmFiles/slurm_outputs
