# LatentHost: Probabilistic host attribution using mobile genetic elements through Bayesian latent class analysis.
A  Bayesian latent class model (BLCM) to systematically integrate multiple accessory elements for probabilistic assignment of host-origins.

### Introduction
 
Detection of mobile genetic elements in conjunction with core-genome features (phylogenetic clades or cgmlst) may identify zoonotic spillover and host switch events. We applied Bayesian latent class model (BLCM) approach that assumes the host-origin for each isolate is in an unobserved class of human, turkey, pork and chicken, with further stratification into three major clades based on core phylogeny. 

BLCM uses multivariate binary responses that indicate presence or absence of 17 host-associated accessory elements, identified previously, to infer the latent host-origins. The latent classes and model parameters can be learned in an unsupervised fashion or using a training set. Markov chain Monte Carlo algorithms are used to iteratively produce samples from the posterior distribution of the unobserved host-origins, based on which we calculate posterior probabilities of host-origins for each isolate.

## Features:

## cgMLST and Kmodes 
Code repository used to generate cgMLST kmodes clustering based on a pre-trained model for cluster predictions.
### requirements:
| Tool            | Version                						       |
| --------------- | -------------------------------------------------------------------------- |
| SLURM           | v23.02.4               						       |
| cgmlstfinder    | https://bitbucket.org/genomicepidemiology/cgmlstfinder/src/master/         |
| cgmlstfinder_db | https://bitbucket.org/genomicepidemiology/cgmlstfinder_db/src/master/      |
| python          | >= v3.8.0              						       |
| perl5 	  | v5.28.1 								       |
| minimap2        | v2.24 								       |
| kmodes          | v0.12.2                                                                    |
| biopython	  | v1.84								       |
| R		  | >=4.1.1 								       |
| optparse	  | v1.7.3 								       |
| coda		  | v0.19-4								       |
| rjags		  | v4-13 								       |
| R2jags 	  | v0.7-1 								       |

* Note: pipeline has been setup to utilze SLURM and array batch submissions.
* Within the script files, there are file paths that need to be changed to your installed directory, as well as conda enviroments that need to be created. Please adjust the conda environment name accordingly if different.
	* It will be "/YOUR/FILE/PATH/HERE/script"
	```
	# Example
	cgmlstfinder_scripts="/YOUR/FILE/PATH/HERE/cgmlstFinder/"
	```
* Please utilize a fresh python conda enviroment and follow the respective installation instructions for cgmlstfinder and kmodes.
* Please utilize a fresh R conda environment for jags and blcm installation.

Ecoli Genomes Training Dataset (N=19453):  
https://drive.google.com/file/d/1cttBcqusUW-1ElP4RdzVKSQP03AfIQZb/view?usp=sharing
```
sha1sum sb27_genomes.tar.gz 
ccc774babc22191d76275c20399b79818dbc314f sb27_genomes.tar.gz
```
These ecoli context genomes is provided in collaboration with Pathogenwatch: https://pathogen.watch/


### Assign cgmlst to genome using CGE-cgmlst database (Folder:cge_cgmlstFinder)
__run_cgmlstFinder.sh__ - starts the cgmlstFinder pipeline. Requires a folder with fasta files, a fasta samplelist text file, and a job name for the output folder. Utilizes slurm job array.
```
bash run_cgmlstFinder.sh (fasta_folder_input) (fasta_sampleList_input) (job_name)
```

__slurmArray_SampleList_Modifier.sh__ - Helper function to generate slurm array ready samplelist.

__cgmlstFinder_submitter.sh__ - Utilizes slurm job array to parallelize and process individual fasta files using cgmlstFinder_runner.sh.

__cgmlstFinder_runner.sh__ - Runs modified version of cgMLST.py (cgMLST_EHS_Modified.py) and CGE_cgMLST_md5_converter.py (CGE_cgMLST_md5_converter_UPDATED.py) to convert cgMLST calls into md5sum. This also uses the ecoli cgMLST db / scheme.

__cgmlstFinder_compile.sh__ - Compiles the outputs from cgmlstFinder_runner.sh and generates a kmodes ready file. Uses the kmodes_ready_inputfile_TEMPLATE.txt which has headers based off of the cgMLST ecoli scheme.

__cgMLSTFinder_git Folder__ - This is the original cgMLSTFinder git with modified codes used in this analysis. 


#### Cluster cgmlst profiles using kmodes clustering (Folder:kmodes_clustering)
__kmodes_submitter.sh__ - starts the kmodes clustering pipeline. Requires the kmodes ready file output from cge_cgmlstFinder pipeline.
```
bash kmodes_submitter.sh (data_tsv) (output_name)
```

__kmodes_runner.sh__ - Runs the kmodes_clustering_modeling.py script to generate trained cluster models.

__kmodes_clustering_modeling.py__ - Python script that uses kmodes to generate trained models based on cgMLST md5sum.

__kmodes_clustering_compiler.sh__ - Script to compile and combined the results from kmodes_clustering_modeling.py into one main output file/folder.
```
sbatch kmodes_clustering_compiler.sh (kmodes_clustering_modeling output) (output_name)
```

__kmodes_clustering_predicting.py__ - Python script that utlizes a trained kmodes model to generate cluster predictions on new cgmlst md5sum.
```
python kmodes_clustering_predicting.py (new kmodes ready file) (trained kmodes model)
```

__FULL_sb27_training_context_kmodes_output_Cluster_2_model.pkl__ - Trained kmodes model on the genome context at k=2 (two clusters) used in this analysis.

## Phylogenetic clades:

## Mobile Genetic Element Detection (Folder:minimap2)

__minimap2_pipeline.sh__ - starts the minimap2 pipeline. Requires fasta folder, its associated host isolation source mapping, and an output name.
```
sbatch minimap2_pipeline.sh (reference_fasta_folder) (reference_fasta_HostLabels) (output_name)
```

The minimap2 portion uses `-cx asm20 --cs=long` to generate paf files with mapQ scoring for hits to the reference fasta file (20221101_elementgeneList.fasta). Additional maf alignment and fasta file are generated for independent evaluation and/or troubleshooting.

__20221101_elementgeneList.fasta__ - Contains the fasta reference sequences for the host element markers for minimap2 to map against.

__removesmalls.pl__ - Helper perl function to trim sequences less than 500 bp.

__minimap2_output_processor.py__ - Python script that processes the paf files from minimap2 into summary files and data frames: summary_df, threshold_count_df, presence_df, proportional_df, host_element_prevalence_df, element_presence_df(s). The element_presence_df are part of the construction of the blcm input file.

## Bayesian Latent Class model (Folder:blcm_R)
__run_hostelement_blca.sh__ - submits a slurm job to run hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20240806.R on the blcm input file.
```
sbatch run_hostelement_blca.sh (blcm input file) (folder output)
```

__hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20240806.R__ - Utilizes jags to run Bayesian latent class model (BLCM) on the host element presence absence input file with host source and kmodes clustering. The bugs model is incorporated into the R code. Please refer to the README.md file in blcm_R folder for further details.
```
hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20240806.R (blcm input file) (folder output)
```
