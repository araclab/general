#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -e kmodes_Submitter_%j.err
#SBATCH -o kmodes_Submitter_%j.out

#config file
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/kmodes/config/minifig.txt"

#conda
conda_base=$(cat "$config_file" | grep __conda_base_loc__@__ | awk -F'__:' '{print $2}' | xargs)
conda_name=$(cat "$config_file" | grep __conda_env_name__@__ | awk -F'__:' '{print $2}' | xargs)

#kmodes
kmodes_loc=$(cat "$config_file" | grep __kmodes_loc__@__ | awk -F'__:' '{print $2}' | xargs)
trained_model=$(cat "$config_file" | grep __trained_model__@__ | awk -F'__:' '{print $2}' | xargs)


#input
kmodes_rdy_inputfile=$1

#check input
if [ $# -lt 1 ]
then
	echo "add input (kmodes_rdy_inputfile)"
	echo	
	echo "note: do not have at dots '.' in inputfile path, as it may ruin output writing!"
fi

sbatch -J kmodes_pred \
	-p project \
	-t 04:00:00 \
	-o kmodes_pred_%j.out \
	-e kmodes_pred_%j.err \
	--cpus-per-task=4 \
	--mem=8GB \
	--wrap ". '$conda_base' && conda activate '$conda_name' && python '$kmodes_loc/kmodes_clustering_predicting.py' '$kmodes_rdy_inputfile' '$trained_model'"

