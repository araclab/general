
few changes made for the pipeline to function, see below.
- Jon 10/12/2025

diff host_element_screen_processor.py /dpssi/data/Projects/mtg_host_elements_files_and_output/proj/araclab_modified_scripts/Food-epidemiology/host_element_v2/pipeline_modules/host_element_pipeline/scripts/helper_scripts/host_element_screen_processor.py
72c72
< host_info_df = pd.read_csv(host_file, sep="\t")
---
> host_info_df = pd.read_csv(host_file, sep="\t", dtype={'Genome_Ref':str})
393c393,394
< wb.save()
---
> #wb.save()
> wb.close() # save is deprecated in newer versions
