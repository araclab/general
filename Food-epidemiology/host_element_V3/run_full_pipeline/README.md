# Full Pipeline Wrapper

This folder is intended to hold the top-level wrapper for the host element Bayesian latent class model pipeline in host_element_V3.

The goal of the wrapper is to run the full workflow from a folder of genome assemblies to final BLCM prediction scores with only three user inputs:

1. An assembly folder
2. A host TSV file
3. An output directory

The wrapper script is:

- `BLCM_analysis.sh`

## Purpose

The full pipeline combines the following major stages:

1. cgMLST calling
2. kmodes cluster prediction from the cgMLST output
3. MLST calling
4. Host element screening and element presence compilation
5. BLCM input compilation
6. Final Bayesian latent class model prediction

This wrapper is meant to reduce the number of manual handoff steps between those modules.

## Expected Inputs

### 1. Assembly folder

This should be a folder containing genome assembly files.

Expected file types:

- `.fasta`
- `.fa`
- `.fna`

Recommended filename rules:

- Do not use spaces
- Do not use commas
- Avoid extra dots in the sample basename when possible
- Keep filenames consistent with the sample IDs used in the host TSV

### 2. Host TSV

This should be a tab-delimited file with at least two columns:

1. Sample ID
2. Host

Example:

```tsv
sampleID	Host
Sample_001	Human
Sample_002	Chicken
Sample_003	Pork
```

The sample IDs in the host file should match the assembly filenames after removing the extension.

### 3. Output directory

This is the top-level destination for the run outputs.

The wrapper is expected to create intermediate folders and final compiled result files inside this location.

## Usage

The wrapper is being written to use flag-based input.

Current intended usage:

```bash
bash BLCM_analysis.sh -i <assembly_folder> -t <host_tsv> -o <output_directory>
```

If the script is submitted through SLURM instead of being run directly with `bash`, use:

```bash
sbatch BLCM_analysis.sh -i <assembly_folder> -t <host_tsv> -o <output_directory>
```

Note:

- `#SBATCH` headers are only used when the script is launched with `sbatch`
- If the script is run with `bash`, those lines are ignored as shell comments

## Pipeline Order

The intended full pipeline order is:

1. Generate a sample list from the input assembly folder
2. Run `pipeline_modules/cgmlstFinder/cgmlstFinder_Submitter.sh`
3. Wait for the compiled cgMLST output that becomes the kmodes-ready input file
4. Run `pipeline_modules_nonessential/MLST/MLST_SLURM/Slurm_Array_Submitter.sh`
5. Wait for the compiled MLST output file
6. Run `pipeline_modules/host_element_pipeline/scripts/host_element_pipeline_Submitter.sh`
7. Wait for the compiled element presence TSV
8. Run `pipeline_modules/kmodes/kmodes_SLURM_Submitter.sh`
9. Use the resulting kmodes prediction CSV together with the MLST and element outputs to build the BLCM input file
10. Run the final BLCM R script

## Important Files Used by the Wrapper

The wrapper depends on values defined in:

- `../config/config.env`

That config file provides:

- Conda activation paths
- Tool locations
- Environment names
- Module script locations
- The trained kmodes model path

The BLCM input compiler and model files currently live in:

- `../pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/compile_input.R`
- `../pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/hostelement_blca_kmodes_CLUST2_SSI_noBeefnTurkey_20260204.R`

The SB27 training base input used for appending new rows currently lives in:

- `../pipeline_modules/host_element_blcm/SB27_excludeBeefnTurkey_18022026/base_blcm_input/SB27_raw_input_26022026.csv`

## Expected Outputs

The exact file names depend on the wrapper implementation, but the final outputs should include at least:

- A sample list generated from the assembly folder
- A compiled MLST results file
- An element presence TSV
- A kmodes prediction CSV
- A compiled BLCM input CSV
- A final BLCM prediction score CSV

For the current no-beef/no-turkey BLCM version, the final prediction output from the model script is expected to be a file ending in:

- `_pred_scores.csv`

## Requirements

This wrapper assumes the host_element_V3 environments and scripts are already configured.

In particular:

- `config.env` must point to working tool paths
- The required conda environments must exist
- SLURM must be available if the pipeline is run in batch mode
- R and JAGS must be available for the final BLCM stage

Useful environment files are stored in:

- `../pipeline_modules/conda_envs/`

## Current Notes

- This folder is for the high-level orchestration layer only
- The individual modules remain the source of truth for the scientific and compute steps
- If a stage is modified, update this README so the described handoff files still match reality
