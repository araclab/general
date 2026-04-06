#!/bin/bash
#SBATCH --time=2-00:00:00
#SBATCH -p project
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH -o blcm_analysis_%j.out
#SBATCH -e blcm_analysis_%j.err


#blcm pipeline wrapper, written by Jon Slotved on 02/04/2026
#please contact via: JOSS@dksund.dk

#config
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

#paths
project_root=$(grep "^GLOBAL__PROJECT_ROOT__=" "$config_file" | awk -F'__=' '{print $2}' | xargs)
echo "main path: $project_root"

#how to use 
print_usage() {
	echo
    echo "Usage: sbatch/bash BLCM_analysis.sh <assembly_folder> <host_tsv> <output_directory> [partition]"
	echo
	echo "Arguments:"
	echo "  assembly_folder  Folder containing genome assemblies in fasta/fa/fna format"
	echo "  host_tsv         TSV file with two columns: sampleID and Host"
	echo "  output_directory Destination folder for intermediate and final outputs"
	echo "  partition        SLURM partition to use (optional, default: project)"
    echo
    echo "PLEASE NOTE: avoid unusual filenames with spaces, commas or dots"
	echo "It is also recommended that full paths are used when filling arguments"
    echo 
}

#get input
input_folder="$1"
host_info="$2"
main_output_folder=${3:-output_blca}
partition=${4:-project}

#check input and print_usage if bad
if [ -z "$input_folder" ] || [ -z "$host_info" ] || [ -z "$main_output_folder" ]; then
    print_usage
	echo
	echo "found information:"
	echo "input_folder: ${input_folder}"
	echo "host_info: ${host_info}"
	echo "output_loc: ${main_output_folder}"
	echo "partition: ${partition}"
    exit 1
fi

#create file system
input_folder=$(cd "$input_folder" && pwd)
host_info=$(readlink -f "$host_info")
mkdir -p "$main_output_folder"
main_output_folder=$(cd "$main_output_folder" && pwd)
mkdir -p "$main_output_folder"/tmp_analysis
cd "$main_output_folder" || { echo "ERROR: cannot cd to $main_output_folder"; exit 1; }
cat "$host_info" | awk -F'\t' '{print $1}' | sed 's/$/\.fasta/' | tail -n +2 > tmp_analysis/sample_list.txt
sample_list="$main_output_folder/tmp_analysis/sample_list.txt"

#run modules

# ── WAVE 1: all modules that only need assemblies, run in parallel ────────────

#cgmlst
cgmlst="$project_root/pipeline_modules/cgmlstFinder"
cgmlst_compiler_jid=$(bash "$cgmlst/cgmlstFinder_Submitter.sh" \
    "$input_folder" \
    "$sample_list" \
    cgmlst_analysis \
    "$partition" | tail -1)
echo "cgmlst compiler: $cgmlst_compiler_jid"

#host element pipeline
hep="$project_root/pipeline_modules/host_element_pipeline/scripts"
hep_caller_jid=$(bash "$hep/host_element_pipeline_Submitter.sh" \
    "$input_folder" \
    "$sample_list" \
    "$host_info" \
    hep_analysis \
    "$partition" | tail -1)
echo "HEP caller: $hep_caller_jid"

#MLST
mlst="$project_root/pipeline_modules_nonessential/MLST/MLST_SLURM"
mlst_compiler_jid=$(bash "$mlst/Slurm_Array_Submitter.sh" \
    "$input_folder" \
    "$sample_list" \
    mlst_analysis \
    "$partition" | tail -1)
echo "MLST compiler: $mlst_compiler_jid"

#fimH (informational only, not needed for BLCM)
fimh="$project_root/pipeline_modules_nonessential/fimHtyper/fimHtyper_SLURM"
bash "$fimh/Slurm_Array_Submitter.sh" \
    "$input_folder" \
    "$sample_list" \
    fimh_analysis \
    "$partition"
echo "fimH submitted (independent)"

# ── WAVE 2: kmodes, depends on cgmlst ────────────────────────────────────────

kmodes="$project_root/pipeline_modules/kmodes"
cgmlst_kmodes_input="$main_output_folder/cgmlst_analysis_output/compiled_files/cgmlst_analysis_kmodes_ready_inputfile.txt"
kmodes_pred_jid=$(bash "$kmodes/kmodes_SLURM_Submitter.sh" \
    "$cgmlst_kmodes_input" \
    "$partition" \
    "$cgmlst_compiler_jid" | grep -E '^[0-9]+$')
echo "kmodes pred: $kmodes_pred_jid"

# ── WAVE 3: BLCM, depends on kmodes + HEP + MLST ─────────────────────────────

blcm="$project_root/pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026"
kmodes_predictions="$main_output_folder/cgmlst_analysis_output/compiled_files/cgmlst_analysis_kmodes_ready_inputfile__Cluster_2__kmodes_cgmlst_clustering_predictions.csv"
hep_elements="$main_output_folder/hep_analysis_output/compiled_files/hep_analysis_element_presence.tsv"
mlst_results="$main_output_folder/mlst_analysis_output/compiled_files/results_compiled.txt"
blcm_output="$main_output_folder/blcm_output"

sbatch -p "${partition}" \
    -J blcm_analysis \
    --dependency=afterok:"${kmodes_pred_jid}":"${hep_caller_jid}":"${mlst_compiler_jid}" \
    "$blcm/run_hostelement_blca.sh" \
    "$kmodes_predictions" \
    "$hep_elements" \
    "$host_info" \
    "$mlst_results" \
    "$blcm_output"

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "========================================"
echo "All jobs submitted:"
echo "  cgmlst compiler : $cgmlst_compiler_jid"
echo "  HEP caller      : $hep_caller_jid"
echo "  MLST compiler   : $mlst_compiler_jid"
echo "  kmodes pred     : $kmodes_pred_jid"
echo "  fimH            : independent"
echo "  output folder   : $main_output_folder"
echo "========================================"
