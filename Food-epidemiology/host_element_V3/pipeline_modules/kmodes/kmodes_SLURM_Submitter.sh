#!/bin/sh

#config file
config_file="config/minifig.txt"

#conda
conda_base=$(cat "$config_file" | grep __conda_base_loc__@__ | awk -F'__:' '{print $2}' | xargs)
conda_name=$(cat "$config_file" | grep __conda_env_name__@__ | awk -F'__:' '{print $2}' | xargs)

#slurm
cpus=$(cat "$config_file" | grep __cpu_usage__@__ | awk -F'__:' '{print $2}' | xargs)
mem=$(cat "$config_file" | grep __mem_usage__@__ | awk -F'__:' '{print $2}' | xargs)

#kmodes
kmodes_loc=$(cat "$config_file" | grep __kmodes_loc__@__ | awk -F'__:' '{print $2}' | xargs)
trained_model=$(cat "$config_file" | grep __trained_model__@__ | awk -F'__:' '{print $2}' | xargs)


#input
kmodes_rdy_inputfile=$1

#check input
if [ $# -lt 2 ]
then
	echo "add input (kmodes_rdy_inputfile) (trained_model.pkl)"
	echo	
	echo "note: do not have at dots '.' in inputfile path, as it may ruin output writing!"
fi


sbatch -J kmodes_pred \
	-p project \
	-t 04:00:00 \
	-o kmodes_pred_%j.out \
	-e kmodes_pred_%j.err \
	--cpus-per-task=$cpus \
	--mem=$mem \
	--wrap ". '$conda_base' && conda activate '$conda_name' && python '$kmodes_loc/kmodes_clustering_predicting.py' '$kmodes_rdy_inputfile' '$trained_model'"

