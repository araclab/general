# Requirements:
* mmseq2 screening is from: /scratch/liu_price_lab/ehsung/github/Development/ehsung/microbiome/mmseq2/scripts/mmseq2_Submitter.sh





# Host_Element_Pipeline Change Log:
## v4.0.1 (08/18/25)
* 20250527_elementgeneList.fasta (ARCHIVED)
	* Current: 20250818_elementgeneList.fasta -- Updated fasta header with new standard format; removed uncessary genes.
	* Gene Count from 315 --> 176 (Significany trim)
	* Kept only genes in the elements used for blcm: 
		* EL18 
		* EL19
		* EL2
		* EL35
		* EL36
		* EL37
		* EL38
		* EL39
		* EL3
		* EL40
		* EL41
		* EL42
		* EL43
		* EL44
		* EL45
		* EL46
		* EL50


## v4.0 (05/27/25)
### host_element_pipeline_Submitter.sh
* Changed from using minimap2 to screen geens to using mmseq2. Changed name to host_element_pipeline due to this major change.
* 20221101_elementgeneList.fasta (ARCHIVED) -- main host element reference file up to Dec, 2024; previous version 3.2 and lower minimap2 pipeline.
* 20250527_elementgeneList.fasta -- modified version of 20221101_elementgeneList.fasta, where we apply the rules identifed by Olivia's CE.
	* Reference file: /scratch/liu_price_lab/ehsung/github/Development/ehsung/Food-epidemiology/host_element_pipeline/reference_files/CE-gene_presence_flagged_05272025.txt 
* Pipeline is broken into steps now due to incorporation of mmseq2 independent pipeline.

### host_element_screen_processor.py
* Changed from minimap2_output_processor.py to host_element_screen_processor.py since this uses mmseq2 insetad of minimap2 for gene screening.
* Frontal processing of the data input to utilize mmseq2 screening and not minimap2.




## v3.2 (01/31/25)
### minimap2_output_processor.py
* Removed MLST mapping requirement and the auto-generated blcm files. This format was only specific to clades, not suitable when implementing other styles of clustering.

### minimap2_pipeline.sh 
* Removed MLST mapping requirement and the auto-generated blcm files. This format was only specific to clades, not suitable when implementing other styles of clustering.



## -v3.1 (03/06/23)
### minimap2_output_processor.py
* Previous versions ignored 0 sized paf files (but this deflated the total data since it removed that data point from calculations, when it should have been marked as 0 for all of its data points, since the element_genes are not present)
* Fixed it by setting all data for 0 paf file genomes as 0 (meaning not present element_genes)
* Added a Query_Hits to summary_df that allows for easier filtering of these 0 paf file genomes
* Added back in the main_data sheet that was an excel dataframe as a continously appended .tsv file: "_Main_Data.tsv"



## -v3.0 (02/23/23)
### minimap2_output_processor.py
* Removed main data sheet from excel (not scalable due to number of rows)
	* Converted dataframe loop insertion to dict into dataframe method
	* Created function to perform dict_to_df
* Currently requires adding underscore (_) separators for elements and genes to properly function
* Replaced main data sheet from excel with Summary_Data
	* Sheet includes: statistics on alignment, mapq, run information, and no hit counts.
* Loops have been combined for each set of dataframes (no more repeated loops for each dataframe)
	* summary_df, threshold_count_df and presence_df
	* proportional_df and host_element_prevalence_df
	* element_presence_df
* Updated the element_presence_df portion with a function to allow for thresholding to be a input variable
	* Updated exporting respectively for any number of thresholds created
	* Converted to dict to df format in function
* Updated host flexibility (doesn't break when Poultry is already part of the host list)
* Updated with the addition of filtered_main_data.tsv that is similar to main_data.tsv, except it filters out low mapq score rows



## v1.5 (02/23/23)
### minimap2_pipeline.sh
* Updated pipeline name to be consistent as one name throughout versioning.
* Updated element_presence tsv file moves to be generic for any threshold values created.
* Fixed moving the pipeline script into appropriate slurm folder.
* Updated to move the created "_Main_Data.tsv" to minimap2_processed
