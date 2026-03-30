# fimHtyper_SLURM

SLURM array wrapper scripts for running FimTyper on a list of fasta files.

## Files

- Slurm_Array_Submitter.sh: main entrypoint that prepares array input and submits jobs
- Slurm_Array_SampleListReady.sh: adds index metadata to sample list for array chunking
- Slurm_Array_Runner.sh: runs FimTyper for one sample per SLURM array task
- Slurm_Array_Compiler.sh: compiles one-line summary per sample and moves compiler logs

## Requirements

- SLURM scheduler with sbatch available
- Conda installed and accessible from the node
- FimTyper tool and fimtyper database present
- A config file at:
  - /dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env

## Config Keys Used

These keys are read from config.env:

- GLOBAL__CONDA_SH__
- FIMHTYPER__CONDA_ENV__
- FIMHTYPER__SLURM_SCRIPTS__
- FIMHTYPER__TOOL_LOCATION__
- FIMHTYPER__DATABASE__

## Input Files

- Data folder: directory containing input fasta files
- Sample list: plain text file with one fasta filename per line
- Job name: label used for SLURM jobs and output folder prefix
- Partition (optional): SLURM partition name for runner and compiler jobs; defaults to `project`

## Run

From this folder:

```bash
sbatch Slurm_Array_Submitter.sh <data_folder> <sample_list.txt> <job_name> [partition]
```

Example:

```bash
sbatch Slurm_Array_Submitter.sh /path/to/Test_data sample_list_example.txt test [partition]

```

## What The Submitter Does

1. Creates indexed sample list:
  - <sample_list_basename>_SLURM-ARRAY-READY.txt (created in current working directory)
2. Creates output folders:
   - <job_name>_output
   - <job_name>_output/processing_files
3. Splits tasks into chunks of up to 1000 samples
4. Submits one or more SLURM array jobs for Slurm_Array_Runner.sh
5. Submits Slurm_Array_Compiler.sh with singleton dependency on the same job name

## Output

Main output structure:

- <job_name>_output/processing_files/<sample>/
  - FimTyper per-sample outputs
  - slurm_outputs/Slurm_Array_Runner_<jobid>_<taskid>.out
  - slurm_outputs/Slurm_Array_Runner_<jobid>_<taskid>.err
- <job_name>_output/compiled_files/results_compiled.txt
- <job_name>_output/compiled_files/slurm_files/Slurm_Array_Compiler_<jobid>.out
- <job_name>_output/compiled_files/slurm_files/Slurm_Array_Compiler_<jobid>.err
- <job_name>_output/slurm/Slurm_Array_Submitter_<jobid>.out
- <job_name>_output/slurm/Slurm_Array_Submitter_<jobid>.err

Compiled file format is tab-separated:

```text
sampleID	fimHtype
107757956831	FimH22
```

If no sample match is found in results_tab.txt, compiler writes:

```text
None_Found
```

## Notes

- Runner uses these FimTyper parameters:
  - -k 95.00
  - -l 0.60
- SLURM array max size is set to 1000 in both submitter and sample list helper.
- If rerunning with the same sample list name, remove `<sample_list_basename>_SLURM-ARRAY-READY.txt` first to avoid duplicated entries.
- Ensure filenames in sample list exactly match files in the data folder.
