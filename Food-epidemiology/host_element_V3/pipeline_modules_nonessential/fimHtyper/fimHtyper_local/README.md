# fimHtyper_local

Local (non-SLURM) wrapper scripts for running FimTyper on a list of fasta files.

## Overview

- **Local version**: Runs sequentially on a single machine; processes one sample at a time in a bash loop
- **SLURM version**: Submits samples as SLURM array jobs for parallel processing on a cluster
- Both versions produce identical output format and apply the same FimTyper parameters

## Files

- `Loca_fimH_Submitter.sh`: main entrypoint (runs locally)
- `Loca_fimH_SampleListReady.sh`: builds indexed sample list
- `Loca_fimH_Runner.sh`: executes FimTyper per sample
- `Loca_fimH_Complier.sh`: aggregates results into summary file
- `sample_list_example.txt`: example sample list

## Configuration

Before running, edit `Loca_fimH_Runner.sh` to set:

```bash
fimtyper="/path/to/Fimtyper"
fimtyper_db="/path/to/Fimtyper/fimtyper_db"
```

Conda environment setup (line ~14):

```bash
conda activate fimtyper  # change if your env has a different name
```

## Quick Run

From this folder:

```bash
bash Loca_fimH_Submitter.sh <data_folder> <sample_list.txt> <job_name>
```

Example:

```bash
bash Loca_fimH_Submitter.sh /path/to/Test_data sample_list_example.txt test
```

## Inputs

- `<data_folder>`: folder containing fasta files
- `<sample_list.txt>`: one fasta filename per line (must match files in data folder)
- `<job_name>`: output folder prefix

## Output

Creates:

- `<job_name>_output/processing_files/<sample>/` (per-sample FimTyper output)
- `<job_name>_output/compiled_files/results_compiled.txt`

Output format (tab-separated):

```text
sampleID	fimHtype
107757956831	FimH22
```

If no sample ID match is found in `results_tab.txt`, compiler writes:

```text
None_Found
```

## Differences from SLURM Version

| Aspect | Local | SLURM |
|--------|-------|-------|
| Execution | Sequential bash loop | Parallel array job submission |
| Config | Hardcoded in scripts | Reads from `config.env` file |
| Conda env | Set directly in script | Read from config file |
| Output cleanup | No SLURM logs folder | Creates `slurm_outputs/` subfolder |
| Speed | Slower (one sample at a time) | Faster (samples in parallel) |
| Infrastructure | Any machine with bash | Cluster with SLURM scheduler |
| Compile logic | Identical | Identical |


