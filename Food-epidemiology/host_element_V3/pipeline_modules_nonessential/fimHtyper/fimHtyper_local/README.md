# fimHtyper_local

Local (non-SLURM) wrapper scripts for running FimTyper on a list of fasta files.

## Files

- `Loca_fimH_Submitter.sh`: main entrypoint (runs locally)
- `Loca_fimH_SampleListReady.sh`: builds indexed sample list
- `Loca_fimH_Runner.sh`: runs FimTyper per sample
- `Loca_fimH_Complier.sh`: compiles one-line summary per sample
- `sample_list_example.txt`: example sample list

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

Compiled file format:

```text
sampleID	fimHtype
107757956831	FimH22
```

If no sample ID match is found in `results_tab.txt`, compiler writes:

```text
None_Found
```

## Hardcoded Paths

`Loca_fimH_Runner.sh` currently uses hardcoded paths for:

- conda source
- conda env (`fimtyper`)
- FimTyper repo path
- FimTyper database path

Update these in the script for your system before running.
