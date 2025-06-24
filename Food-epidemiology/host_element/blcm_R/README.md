A  Bayesian latent class model (BLCM) to systematically integrate multiple accessory elements for probabilistic assignment of host-origins.

### Introduction
 
Detection of mobile genetic elements in conjunction with core-genome phylogenetics may identify zoonotic spillover and host switch events. We applied Bayesian latent class model approach that assumes the host-origin for each isolate is in an unobserved class of human, turkey, pork and chicken, with further stratification into three major clades based on core phylogeny. 

BLCM uses multivariate binary responses that indicate presence or absence of 18 host-associated accessory elements, identified previously, to infer the latent host-origins. The latent classes and model parameters can be learned in an unsupervised fashion or using a training set. Markov chain Monte Carlo algorithms are used to iteratively produce samples from the posterior distribution of the unobserved host-origins, based on which we calculate posterior probabilities of host-origins for each isolate.

### Critical Modifications that should be made for every run
The code for classes needs to be updated if the hosts change. i.e. if you have added beef , update the code to incoporate a new class. if you removed chicken -> update code. Please ask someone who has updated the code before to help!

### Requirement
- R => v.3.3.1
- JAGS => v.4.2.0

### Input format
A matrix with Order of the columns needs to be kept the same as below:

| Column Name | Description 														   |
| ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| ID 	      | Isolate/Genome unique Identifier 											   |
| training    | 0/1, if its a genome from the training then the value is1, else 0 							   |
| MLST 	      | multi locus sequence type number 											   |
| Human_CL1   | 0/1, if the isolation source of the genome is 'Human' and cgMLST Kmodes Clustering predicts in cluster 1, then 1, else 0   |
| Human_CL2   | 0/1, if the isolation source of the genome is 'Human' and cgMLST Kmodes Clustering predicts in cluster 2, then 1, else 0   |
| Chicken_CL1 | 0/1, if the isolation source of the genome is 'Chicken' and cgMLST Kmodes Clustering predicts in cluster 1, then 1, else 0 |
| Chicken_CL2 | 0/1, if the isolation source of the genome is 'Chicken' and cgMLST Kmodes Clustering predicts in cluster 2, then 1, else 0 |
| Turkey_CL1  | 0/1, if the isolation source of the genome is 'Turkey' and cgMLST Kmodes Clustering predicts in cluster 1, then 1, else 0  |
| Turkey_CL2  | 0/1, if the isolation source of the genome is 'Turkey' and cgMLST Kmodes Clustering predicts in cluster 2, then 1, else 0  |
| Pork 	      | 0/1, if the isolation source of the genome is 'Pork', then 1, else 0 						           |
| Beef 	      | 0/1, if the isolation source of the genome is 'Beef', then 1, else 0  							   |
| CL1 	      | 0/1, if the cgMLST Kmodes Clustering predicts in cluster 1, then 1, else 0 						   |
| CL2 	      | 0/1, if the cgMLST Kmodes Clustering predicts in cluster 2, then 1, else 0 						   |
| EL18        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL19        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL2 	      | 0/1, if the element was found in genome then 1, else 0 									   |
| EL3 	      | 0/1, if the element was found in genome then 1, else 0 									   |
| EL35        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL36        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL37        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL38        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL39        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL40        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL41        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL42        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL43        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL44        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL45        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL46        | 0/1, if the element was found in genome then 1, else 0                                                                     |
| EL50        | 0/1, if the element was found in genome then 1, else 0                                                                     |

### Output format

| Column Name      | Description						         	     |
| ---------------- | ------------------------------------------------------------------------------- |
| Output ID        | ID generated by the script (ignore this column) 				     |
| pred_Human_CL1   | Positive Predictive Value for the genome to have a Human source in cluster 1    |
| pred_Human_CL2   | Positive Predictive Value for the genome to have a Human source in cluster 2    |
| pred_Chicken_CL1 | Positive Predictive Value for the genome to have a Chicken source in cluster 1  |
| pred_Chicken_CL2 | Positive Predictive Value for the genome to have a Chicken source in cluster 2  |
| pred_Turkey_CL1  | Positive Predictive Value for the genome to have a Turkey source in cluster 1   |
| pred_Turkey_CL2  | Positive Predictive Value for the genome to have a Turkey source in cluster 2   |
| pred_Pork        | Positive Predictive Value for the genome to have a Pork source 		     |
| pred_Beef    	   | Positive Predictive Value for the genome to have a Beef source 		     |

The rest of the columns are the same as the input file.
 
To get the host source prediction for a genome, sum the Positive Predictive Value for that host. 

### Usage
```
Rscript hostelement_blca_kmodes_CLUST2_BeefColumnAdded_20240806.R -i $CSV_Input -o $Folder_Output
```

### Result Interpretation
To obtain a dichotomous classification (i.e., meat or human origin), we apply a user-defined probability thresholds of ≥ 0.80 for positive and ≤ 0.20 for negative; probabilities between these two values were considered indeterminate. 

### Citation
If you use BLCM - Host Elements, please cite:

[Using source-associated mobile genetic elements to identify zoonotic extraintestinal E.coli infections](https://www.sciencedirect.com/science/article/pii/S2352771423000381)

```
Cindy M. Liu, Maliha Aziz, Daniel E. Park, Zhenke Wu, Marc Stegger, Mengbing Li, Yashan Wang, Kara Schmidlin, Timothy J. Johnson, Benjamin J. Koch, Bruce A. Hungate, Lora Nordstrom, Lori Gauld, Brett Weaver, Diana Rolland, Sally Statham, Brantley Hall, Sanjeev Sariya, Gregg S. Davis, Paul S. Keim, James R. Johnson, Lance B. Price,
Using source-associated mobile genetic elements to identify zoonotic extraintestinal E. coli infections,
One Health, 2023, 100518, ISSN 2352-7714, https://doi.org/10.1016/j.onehlt.2023.100518.
```
