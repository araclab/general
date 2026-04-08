#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -e kmodes_Submitter_%j.err
#SBATCH -o kmodes_Submitter_%j.out

#config file
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
config_file="$PROJECT_DIR/config/config.env"

#conda
conda_base=$(grep '^GLOBAL__CONDA_SH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
conda_name=$(grep '^KMODES__CONDA_ENV__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
#conda activated in job acttivation

#kmodes
project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
kmodes_loc="$project_root/pipeline_modules/kmodes"
trained_model="$project_root/pipeline_modules/kmodes/trained_models/cluster_2/FULL_sb27_training_context_kmodes_output_Cluster_2_model.pkl"


#input
kmodes_rdy_inputfile=$1
partition=${2:-project}
dependency=${3:-}

#build dependency flag if provided
dep_flag=""
if [ -n "$dependency" ]; then
	dep_flag="--dependency=afterok:${dependency}"
fi

#check input
if [ $# -lt 1 ]; then
	echo "add input (kmodes_rdy_inputfile)"
	echo
	echo "note: do not have at dots '.' in inputfile path, as it may ruin output writing!"
	exit 1
fi


kmodes_pred_jid=$(sbatch --parsable -J kmodes_pred \
	-p "$partition" \
	$dep_flag \
	-t 04:00:00 \
	-o kmodes_pred_%j.out \
	-e kmodes_pred_%j.err \
	--cpus-per-task=4 \
	--mem=8GB \
	--wrap ". '$conda_base' && conda activate '$conda_name' && python '$kmodes_loc/kmodes_clustering_predicting.py' '$kmodes_rdy_inputfile' '$trained_model'")
echo "$kmodes_pred_jid"

#move slurm files