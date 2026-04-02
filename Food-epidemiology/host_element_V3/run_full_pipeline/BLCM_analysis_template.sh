#!/bin/bash

set -e
set -u
set -o pipefail

print_usage() {
	echo "Usage: bash BLCM_analysis.sh <assembly_folder> <host_tsv> <output_directory>"
	echo
	echo "assembly_folder : Folder containing genome assemblies in fasta/fa/fna format"
	echo "host_tsv        : TSV file with two columns: sampleID and Host"
	echo "output_directory: Destination folder for intermediate and final outputs"
}

fail_with_message() {
	message_text="$1"
	echo "ERROR: $message_text" >&2
	exit 1
}

log_step() {
	message_text="$1"
	echo
	echo "============================================================"
	echo "$message_text"
	echo "============================================================"
}

get_config_value() {
	config_key="$1"
	config_value=$(grep "^${config_key}=" "$CONFIG_FILE" | awk -F'=' '{print $2}' | xargs)

	if [ -z "$config_value" ]; then
		fail_with_message "Missing config value for ${config_key} in ${CONFIG_FILE}"
	fi

	echo "$config_value"
}

wait_for_file() {
	target_file="$1"
	file_description="$2"
	timeout_seconds="$3"

	elapsed_seconds=0
	sleep_interval_seconds=30

	while true
	do
		if [ -f "$target_file" ]; then
			break
		fi

		if [ "$elapsed_seconds" -ge "$timeout_seconds" ]; then
			fail_with_message "Timed out waiting for ${file_description}: ${target_file}"
		fi

		echo "Waiting for ${file_description}: ${target_file}"
		sleep "$sleep_interval_seconds"
		elapsed_seconds=$((elapsed_seconds + sleep_interval_seconds))
	done
}

require_command() {
	command_name="$1"

	if command -v "$command_name" >/dev/null 2>&1; then
		return
	fi

	fail_with_message "Required command not found: ${command_name}"
}

generate_sample_list() {
	assembly_folder_path="$1"
	sample_list_output_file="$2"

	temporary_sample_list_file="${sample_list_output_file}.tmp"
	: > "$temporary_sample_list_file"

	while IFS= read -r -d '' assembly_path
	do
		assembly_filename=$(basename "$assembly_path")
		echo "$assembly_filename" >> "$temporary_sample_list_file"
	done < <(
		find "$assembly_folder_path" \
			-maxdepth 1 \
			-type f \
			\( -iname "*.fasta" -o -iname "*.fa" -o -iname "*.fna" \) \
			-print0
	)

	sort "$temporary_sample_list_file" > "$sample_list_output_file"
	rm -f "$temporary_sample_list_file"

	if [ -s "$sample_list_output_file" ]; then
		return
	fi

	fail_with_message "No fasta, fa, or fna files were found in ${assembly_folder_path}"
}

require_two_column_tsv() {
	host_file_path="$1"
	host_file_column_count=$(awk -F'\t' 'NR == 1 {print NF; exit}' "$host_file_path")

	if [ -z "$host_file_column_count" ]; then
		fail_with_message "Host TSV is empty: ${host_file_path}"
	fi

	if [ "$host_file_column_count" -lt 2 ]; then
		fail_with_message "Host TSV must have at least two tab-delimited columns: sampleID and Host"
	fi
}

run_compile_input() {
	base_input_file_path="$1"
	kmodes_prediction_file_path="$2"
	mlst_compiled_file_path="$3"
	element_presence_file_path="$4"
	host_file_path="$5"
	compile_output_directory="$6"

	Rscript "$COMPILE_INPUT_SCRIPT" \
		-s "$base_input_file_path" \
		-k "$kmodes_prediction_file_path" \
		-m "$mlst_compiled_file_path" \
		-e "$element_presence_file_path" \
		-t "$host_file_path" \
		-o "$compile_output_directory"
}

submit_blcm_job() {
	compiled_input_file_path="$1"
	working_directory_path="$2"
	blcm_output_name="$3"

	conda_source_path=$(get_config_value "GLOBAL__CONDA_SH__")
	blcm_conda_environment=$(get_config_value "BLCM__CONDA_ENV__")

	require_command "sbatch"

	blcm_job_id=$(sbatch \
		--parsable \
		-J "$BLCM_JOB_NAME" \
		-p project \
		-t 3-00:00:00 \
		-o "$working_directory_path/${BLCM_JOB_NAME}_%j.out" \
		-e "$working_directory_path/${BLCM_JOB_NAME}_%j.err" \
		--cpus-per-task=4 \
		--wrap ". '$conda_source_path'; conda activate '$blcm_conda_environment'; module load R/4.1.1; cd '$working_directory_path'; Rscript '$BLCM_MODEL_SCRIPT' -i '$compiled_input_file_path' -o '$blcm_output_name'"
	)

	if [ -z "$blcm_job_id" ]; then
		fail_with_message "Failed to submit the BLCM job"
	fi

	echo "$blcm_job_id"
}

if [ "$#" -lt 3 ]; then
	print_usage
	fail_with_message "Please provide all 3 required arguments"
fi

ASSEMBLY_FOLDER_INPUT="$1"
HOST_TSV_INPUT="$2"
OUTPUT_DIRECTORY_INPUT="$3"

if [ -d "$ASSEMBLY_FOLDER_INPUT" ]; then
	:
else
	fail_with_message "Assembly folder not found: ${ASSEMBLY_FOLDER_INPUT}"
fi

if [ -f "$HOST_TSV_INPUT" ]; then
	:
else
	fail_with_message "Host TSV not found: ${HOST_TSV_INPUT}"
fi

ASSEMBLY_FOLDER=$(cd "$ASSEMBLY_FOLDER_INPUT" && pwd)
HOST_TSV=$(cd "$(dirname "$HOST_TSV_INPUT")" && pwd)/$(basename "$HOST_TSV_INPUT")
mkdir -p "$OUTPUT_DIRECTORY_INPUT"
OUTPUT_DIRECTORY=$(cd "$OUTPUT_DIRECTORY_INPUT" && pwd)

require_two_column_tsv "$HOST_TSV"

SCRIPT_DIRECTORY=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIRECTORY/.." && pwd)
CONFIG_FILE="$REPO_ROOT/config/config.env"

CGMLST_SUBMITTER_SCRIPT="$REPO_ROOT/pipeline_modules/cgmlstFinder/cgmlstFinder_Submitter.sh"
MLST_SUBMITTER_SCRIPT="$REPO_ROOT/pipeline_modules_nonessential/MLST/MLST_SLURM/Slurm_Array_Submitter.sh"
HOST_ELEMENT_SUBMITTER_SCRIPT="$REPO_ROOT/pipeline_modules/host_element_pipeline/scripts/host_element_pipeline_Submitter.sh"
KMODES_SUBMITTER_SCRIPT="$REPO_ROOT/pipeline_modules/kmodes/kmodes_SLURM_Submitter.sh"
COMPILE_INPUT_SCRIPT="$REPO_ROOT/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/compile_input.R"
BLCM_MODEL_SCRIPT="$REPO_ROOT/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/hostelement_blca_kmodes_CLUST2_SSI_noBeefnTurkey_20260204.R"
BASE_SB27_INPUT_FILE="$REPO_ROOT/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/base_blcm_input/SB27_raw_input_26022026.csv"

require_command "bash"
require_command "Rscript"
require_command "find"
require_command "sort"

if [ -f "$CONFIG_FILE" ]; then
	:
else
	fail_with_message "Config file not found: ${CONFIG_FILE}"
fi

if [ -f "$CGMLST_SUBMITTER_SCRIPT" ]; then
	:
else
	fail_with_message "cgMLST submitter not found: ${CGMLST_SUBMITTER_SCRIPT}"
fi

if [ -f "$MLST_SUBMITTER_SCRIPT" ]; then
	:
else
	fail_with_message "MLST submitter not found: ${MLST_SUBMITTER_SCRIPT}"
fi

if [ -f "$HOST_ELEMENT_SUBMITTER_SCRIPT" ]; then
	:
else
	fail_with_message "Host element submitter not found: ${HOST_ELEMENT_SUBMITTER_SCRIPT}"
fi

if [ -f "$KMODES_SUBMITTER_SCRIPT" ]; then
	:
else
	fail_with_message "kmodes submitter not found: ${KMODES_SUBMITTER_SCRIPT}"
fi

if [ -f "$COMPILE_INPUT_SCRIPT" ]; then
	:
else
	fail_with_message "compile_input.R not found: ${COMPILE_INPUT_SCRIPT}"
fi

if [ -f "$BLCM_MODEL_SCRIPT" ]; then
	:
else
	fail_with_message "BLCM model script not found: ${BLCM_MODEL_SCRIPT}"
fi

if [ -f "$BASE_SB27_INPUT_FILE" ]; then
	:
else
	fail_with_message "Base SB27 input file not found: ${BASE_SB27_INPUT_FILE}"
fi

RUN_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORKING_DIRECTORY="$OUTPUT_DIRECTORY/pipeline_run_${RUN_TIMESTAMP}"
FINAL_OUTPUT_DIRECTORY="$OUTPUT_DIRECTORY/final_outputs"

mkdir -p "$WORKING_DIRECTORY"
mkdir -p "$FINAL_OUTPUT_DIRECTORY"

SAMPLE_LIST_FILE="$WORKING_DIRECTORY/sample_list.txt"

CGMLST_JOB_NAME="cgmlst_${RUN_TIMESTAMP}"
MLST_JOB_NAME="mlst_${RUN_TIMESTAMP}"
HOST_ELEMENT_JOB_NAME="host_element_${RUN_TIMESTAMP}"
BLCM_JOB_NAME="blcm_${RUN_TIMESTAMP}"

CGMLST_READY_FILE="$WORKING_DIRECTORY/${CGMLST_JOB_NAME}_output/compiled_files/${CGMLST_JOB_NAME}_kmodes_ready_inputfile.txt"
MLST_COMPILED_FILE="$WORKING_DIRECTORY/${MLST_JOB_NAME}_output/compiled_files/results_compiled.txt"
ELEMENT_PRESENCE_FILE="$WORKING_DIRECTORY/${HOST_ELEMENT_JOB_NAME}_output/compiled_files/${HOST_ELEMENT_JOB_NAME}_element_presence.tsv"
KMODES_INPUT_FILE="$WORKING_DIRECTORY/kmodes_input.txt"
KMODES_PREDICTION_FILE="$WORKING_DIRECTORY/kmodes_input__Cluster_2__kmodes_cgmlst_clustering_predictions.csv"
COMPILED_BLCM_INPUT_FILE="$WORKING_DIRECTORY/final_blcm_input.csv"
BLCM_OUTPUT_NAME="blcm_results"
BLCM_PREDICTION_FILE="$WORKING_DIRECTORY/${BLCM_OUTPUT_NAME}_pred_scores.csv"

log_step "Generating sample list"
generate_sample_list "$ASSEMBLY_FOLDER" "$SAMPLE_LIST_FILE"

cd "$WORKING_DIRECTORY" || fail_with_message "Unable to change directory to ${WORKING_DIRECTORY}"

log_step "Submitting cgMLST pipeline"
bash "$CGMLST_SUBMITTER_SCRIPT" "$ASSEMBLY_FOLDER" "$SAMPLE_LIST_FILE" "$CGMLST_JOB_NAME"
wait_for_file "$CGMLST_READY_FILE" "cgMLST compiled input" 86400

log_step "Submitting MLST pipeline"
bash "$MLST_SUBMITTER_SCRIPT" "$ASSEMBLY_FOLDER" "$SAMPLE_LIST_FILE" "$MLST_JOB_NAME"
wait_for_file "$MLST_COMPILED_FILE" "MLST compiled results" 86400

log_step "Submitting host element pipeline"
bash "$HOST_ELEMENT_SUBMITTER_SCRIPT" "$ASSEMBLY_FOLDER" "$SAMPLE_LIST_FILE" "$HOST_TSV" "$HOST_ELEMENT_JOB_NAME"
wait_for_file "$ELEMENT_PRESENCE_FILE" "element presence results" 86400

log_step "Submitting kmodes prediction"
cp "$CGMLST_READY_FILE" "$KMODES_INPUT_FILE"
bash "$KMODES_SUBMITTER_SCRIPT" "$(basename "$KMODES_INPUT_FILE")"
wait_for_file "$KMODES_PREDICTION_FILE" "kmodes prediction results" 21600

log_step "Compiling BLCM input"
run_compile_input \
	"$BASE_SB27_INPUT_FILE" \
	"$KMODES_PREDICTION_FILE" \
	"$MLST_COMPILED_FILE" \
	"$ELEMENT_PRESENCE_FILE" \
	"$HOST_TSV" \
	"$WORKING_DIRECTORY"

wait_for_file "$COMPILED_BLCM_INPUT_FILE" "compiled BLCM input" 3600

log_step "Submitting final BLCM model"
submit_blcm_job "$COMPILED_BLCM_INPUT_FILE" "$WORKING_DIRECTORY" "$BLCM_OUTPUT_NAME" >/dev/null
wait_for_file "$BLCM_PREDICTION_FILE" "BLCM prediction scores" 172800

log_step "Copying final outputs"
cp "$SAMPLE_LIST_FILE" "$FINAL_OUTPUT_DIRECTORY/sample_list.txt"
cp "$MLST_COMPILED_FILE" "$FINAL_OUTPUT_DIRECTORY/mlst_results_compiled.txt"
cp "$ELEMENT_PRESENCE_FILE" "$FINAL_OUTPUT_DIRECTORY/element_presence.tsv"
cp "$KMODES_PREDICTION_FILE" "$FINAL_OUTPUT_DIRECTORY/kmodes_predictions.csv"
cp "$COMPILED_BLCM_INPUT_FILE" "$FINAL_OUTPUT_DIRECTORY/final_blcm_input.csv"
cp "$BLCM_PREDICTION_FILE" "$FINAL_OUTPUT_DIRECTORY/blcm_pred_scores.csv"

echo
echo "Pipeline complete. Final outputs are in: $FINAL_OUTPUT_DIRECTORY"
