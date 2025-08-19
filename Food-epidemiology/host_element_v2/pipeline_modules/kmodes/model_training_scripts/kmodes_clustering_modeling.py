# Adapted from Julio DC kmodes codes (https://github.com/cgps-group/sb27_analyses/tree/main/clustering)
# Adapted by Edward Sung (edward.sung@gwu.edu)
# Modified on: 09/05/2023
# Updated on: 2/26/24 - Modeling - Edward

# kmodes_clustering_modeling.py takes in a matrix (colunmns = features; rows = samples) and performs kmodes clustering and generates labels for them.

# To Run:
# python kmodes_clustering_modeling.py (input tab delimited file) (cluster_k) (output file names)


# Import Packages
import numpy as np
import pandas as pd
import os
import argparse
import joblib
from kmodes.kmodes import KModes
from kmodes import kprototypes
from sklearn.metrics import silhouette_score

#%% Argument Parsers
parser = argparse.ArgumentParser()
parser.add_argument("input_tsv_data", help="User provided input tsv data file with columns as features (alleles) and rows as samples; manually rename the first column name to be 'Genome' if needed")
parser.add_argument("cluster_k", help="User provided cluseter k input")
parser.add_argument("output_name", help="User provided output_file_name")
args = parser.parse_args()

input_tsv_data = args.input_tsv_data
cluster_k = int(args.cluster_k)
output_name = args.output_name


#%% Testing Purposes
# input_tsv_data = "subset_sb27_training_context_kmodes_ready_inputfile.txt"
# cluster_k = 2
# output_name = "testrun"


#%% Import Data and Format Data
rawData = pd.read_csv(input_tsv_data, sep="\t")
rawData.rename(columns={"Genome": "GenomeID"}, inplace=True)
cleanData = rawData.set_index('GenomeID')


#%% Functions
# Distance calculations for catagorical columns
def create_dm(dataset):
    '''
    Code modified from https://codinginfinite.com/silhouette-coefficient-for-k-modes-and-k-prototypes-clustering/#:~:text=The%20average%20silhouette%20score%20for%20a%20given%20dataset%20lies%20between,dataset%20is%20closer%20to%201.
    By Julio DC
    '''
    if type(dataset).__name__=='DataFrame':
        dataset=dataset.values
    lenDataset=len(dataset)
    distance_matrix=np.zeros(lenDataset*lenDataset).reshape(lenDataset,lenDataset)
    for i in range(lenDataset):
        for j in range(lenDataset):
            x1= dataset[i].reshape(1,-1)
            x2= dataset[j].reshape(1,-1)
            distance=kprototypes.matching_dissim(x1, x2)
            distance_matrix[i][j]=distance
            distance_matrix[j][i]=distance
    return distance_matrix


#%% Run Modeling with cluster_k
print("Running Train Model")
# Initialize kmodes
km = KModes(n_clusters=cluster_k, n_init=50, max_iter=500, verbose=1, init='Cao', n_jobs=-1, random_state=123)

# Train model
trained_km = km.fit(cleanData)


#%% Silhouette Score Calculations
# Calculate distance
cleanedData_distance=create_dm(cleanData)

ss = silhouette_score(cleanedData_distance, trained_km.labels_, metric="precomputed")
print(f'Silhouette Score(cluster_k=' + str(cluster_k) + '): ' + str(ss))


#%%
print("Running compile results")
# Compile Cluster Results
results_df = pd.DataFrame(rawData.GenomeID)
new_column = "cluster_" + str(cluster_k)
results_df[new_column] = trained_km.predict(cleanData)

# Add 1 to cluster to shift from base 0... so its cluster 1, 2, 3, 4, etc
results_df[new_column] = results_df[new_column] + 1

#%% Export Data
print("Running export data")
# Save model as a pickle
model_save_output_name = output_name + "_Cluster_" + str(cluster_k) + "_model.pkl"
joblib.dump(trained_km, model_save_output_name)

results_save_output_name = output_name + "_Cluster_" + str(cluster_k) + "_clusters.csv"
results_df.to_csv(results_save_output_name, index=False)

print("kmodes modeling complete, thank you!")
