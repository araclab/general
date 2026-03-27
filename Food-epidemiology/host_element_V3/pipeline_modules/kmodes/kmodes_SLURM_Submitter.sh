#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -e kmodes_Submitter_%j.err
#SBATCH -o kmodes_Submitter_%j.out

#config file
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

#conda
conda_base=$(grep '^GLOBAL__CONDA_SH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
conda_name=$(grep '^KMODES__CONDA_ENV__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
#conda activated in job acttivation

#kmodes
kmodes_loc=$(grep KMODES__SCRIPTS__= "$config_file" | awk -F'__=' '{print $2}' | xargs)
trained_model=$(grep KMODES__TRAINED_MODEL__= "$config_file" | awk -F'__=' '{print $2}' | xargs)


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

#move slurm files