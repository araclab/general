# Adapted from Julio DC kmodes codes (https://github.com/cgps-group/sb27_analyses/tree/main/clustering)
# Adapted by Edward Sung (edward.sung@gwu.edu)
# Modified on: 09/05/2023
# Updated on: 2/26/24 - Modeling - Edward

# kmodes_clustering_predicting.py takes in a matrix (colunmns = features; rows = samples) and performs predicting based on a kmodes model.

# To Run:
# python kmodes_clustering_predicting.py (input tab delimited file) (kmodes_model)


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
parser.add_argument("kmodes_model", help="User provided kmodes_model input")
args = parser.parse_args()

input_tsv_data = args.input_tsv_data
kmodes_model = args.kmodes_model


#%% Testing Purposes
# input_tsv_data = "subset_sb27_training_context_kmodes_ready_inputfile.txt"
# kmodes_model = "sb27_training_context_kmodes_Cluster_4_model.pkl"

#%% Import Data and Format Data
print("Loading Data")
rawData = pd.read_csv(input_tsv_data, sep="\t")
rawData.rename(columns={"Genome": "GenomeID"}, inplace=True)
cleanData = rawData.set_index('GenomeID')

trained_km = joblib.load(kmodes_model)

#%% Run Prediction using the loaded kmodes model
print("Running Prediction")

results_df = pd.DataFrame(rawData.GenomeID)
new_column = "cluster_" + str(trained_km.n_clusters)
results_df[new_column] = trained_km.predict(cleanData)

# Add 1 to cluster to shift from base 0... so its cluster 1, 2, 3, 4, etc
results_df[new_column] = results_df[new_column] + 1

#%% Export Data
print("Running export data")
filename = input_tsv_data.split(".")[0]
results_save_output_name = filename + "__Cluster_" + str(trained_km.n_clusters) + "__kmodes_cgmlst_clustering_predictions.csv"
results_df.to_csv(results_save_output_name, index=False)

print("kmodes cgmlst predictions, thank you!")
