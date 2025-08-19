#!/bin/sh
#SBATCH --time 4:00:00
#SBATCH -p tiny
#SBATCH -o kmodes_clustering_compiler_%j.out
#SBATCH -e kmodes_clustering_compiler_%j.err


# Conda Environment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate sklearn-env


# User Inputs
main_output_folder=$1
output_name_input=$2

# Create list of sample folders
ls $main_output_folder | grep -v "compiled_results"  > tmplist_output_folders


# Compile the silhouette scores
mkdir $main_output_folder/compiled_results/tmp_clusteringfiles
touch $main_output_folder/compiled_results/silhouette_score_compiled.txt


# Loop through your output folders to compile your results
while read -r line
do
   echo "Extracting results from: $line"
   cat $main_output_folder/${line}/slurm_outputs/*.out | grep "Silhouette Score" >> $main_output_folder/compiled_results/silhouette_score_compiled.txt
   cp $main_output_folder/${line}/*_clusters.csv $main_output_folder/compiled_results/tmp_clusteringfiles
done < tmplist_output_folders

# Compile the clustering csv results
echo "Merging clustering csv results"
csvjoin -c GenomeID $main_output_folder/compiled_results/tmp_clusteringfiles/*_clusters.csv > $main_output_folder/compiled_results/${output_name_input}_clusters.csv

# Temp Fix, csvjoin is treating 0 and 1, as false and true
sed -i 's/False/0/g' $main_output_folder/compiled_results/${output_name_input}_clusters.csv
sed -i 's/True/1/g' $main_output_folder/compiled_results/${output_name_input}_clusters.csv

# Clean-up File System
rm -r $main_output_folder/compiled_results/tmp_clusteringfiles
rm tmplist_output_folders
mv kmodes_clustering_compiler_${SLURM_JOB_ID}.out slurmFiles/slurm_outputs
mv kmodes_clustering_compiler_${SLURM_JOB_ID}.err slurmFiles/slurm_outputs
