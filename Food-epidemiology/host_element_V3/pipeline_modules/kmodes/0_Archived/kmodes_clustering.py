# Adapted from Julio DC kmodes codes (https://github.com/cgps-group/sb27_analyses/tree/main/clustering)
# Adapted by Edward Sung (edward.sung@gwu.edu)
# Modified on: 09/05/2023

# kmodes_clustering.py takes in a matrix (colunmns = features; rows = samples) and performs kmodes clustering and generates labels for them.

# To Run:
# python kmodes_clustering.py (input csv file) (output file names)


# Import Packages
import numpy as np
import pandas as pd
import os
import xlsxwriter
import argparse
import pickle
from kmodes.kmodes import KModes
from kmodes import kprototypes
from sklearn.metrics import silhouette_score



#%% Argument Parsers
parser = argparse.ArgumentParser()
parser.add_argument("input_csv_data", help="User provided input csv data file with columns as features and rows as samples; manually rename the first column name to be 'Genome'")
parser.add_argument("output_name", help="User provided output_file_name")
args = parser.parse_args()

input_csv_data = args.input_csv_data
output_name = args.output_name


#%% Import Data
rawData = pd.read_csv(input_csv_data)

# Clean-up and Preprocess (Transpose) Data
rawData.rename(columns={"Genome": "GenomeID"}, inplace=True)

# cleanedData_T = rawData.set_index('GenomeID').T # Tranpose data (T)

# Tranpose was for nasp/gubbins SNPS matrix format, its not needed here, so its skipped.
cleanedData_T = rawData.set_index('GenomeID')
cleanedData_T_NP = np.array(cleanedData_T) # Convert to numpy array (NP)


#%% Functions
# Distance calculations for catagorical columns
def create_dm(dataset):
    '''
    Code modified from https://codinginfinite.com/silhouette-coefficient-for-k-modes-and-k-prototypes-clustering/#:~:text=The%20average%20silhouette%20score%20for%20a%20given%20dataset%20lies%20between,dataset%20is%20closer%20to%201.
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


#%% Train kmodes models (2 - 20)
# Number of models can be converted into an input value from min to max number of models
k_min = 2
k_max = 6

# Initialize dictionary for data; keys are the model numbers, values are the trained model itself at that k
models_dict = dict()

for k in range(k_min,k_max):

  # Initialize kmodes
  km = KModes(n_clusters=k, n_init=10, verbose=1, n_jobs=-1, random_state=123)

  # Train model
  trained_km = km.fit(cleanedData_T_NP)

  # Add trained model to dict
  models_dict[k] = trained_km


# Silhouette Score Calculations
# Calculate distance
cleanedData_T_NP_distance=create_dm(cleanedData_T_NP)

#for k in models_dict:
#  ss = silhouette_score(cleanedData_T_NP_distance, models_dict[k].labels_, metric="precomputed")
#  print(f'Silhouette Score(n=' + str(k) + '): ' + str(ss))


# Compile Cluster Results
cleanedData_clusters_df = pd.DataFrame()

for k in models_dict:
    cleanedData_clusters_df[k] = models_dict[k].predict(cleanedData_T_NP)


# Export Data
# Save models_dict as a pickle
models_file_output_name = output_name + "_models_dict.pkl"
with open(models_file_output_name, 'wb') as handle:
    pickle.dump(models_dict, handle, protocol=pickle.HIGHEST_PROTOCOL)

dataframe_output_name = output_name + "_clusters_df.csv"
cleanedData_clusters_df.to_csv(dataframe_output_name)
