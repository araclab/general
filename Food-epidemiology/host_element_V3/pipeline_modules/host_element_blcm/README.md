A  Bayesian latent class model (BLCM) to systematically integrate multiple accessory elements for probabilistic assignment of host-origins.


### Critical Modifications that should be made for every run
The code for classes needs to be updated if the hosts change. i.e. if you have added beef , update the code to incoporate a new class. if you removed chicken -> update code. Please ask someone who has updated the code before to help!

There are currenly two versions that have their own folders:
* Excludes_beef/
* Includes_beef/

The difference are within the R code, where the beef class has been either included or excluded, with lines adjusted accordingly. To identify which lines and make your own adjustments based on the classes you do have, please utilize the diff function (or any public software) to compare the R code between the excludes and includes folder.

The other difference is in the base_blcm_input folder csv file base file. The impacted columns would be the front columns containing the host specifics combinations with the kmodes clustering (Human_CL1,Human_CL2,Chicken_CL1,Chicken_CL2,etc). These should only contain the columns in which you do have classes for. Given that the training set does include all of those current hosts, these would remain. The Excludes_beef does not have any beef samples, thus it has been removed as a column. In the Includes_beef, this column is kept, because there are built in samples that are beef.


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


```
