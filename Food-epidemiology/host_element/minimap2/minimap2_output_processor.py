# minimap2_output_processor.py script works as part of minimap2_pipeline_vx.x.sh.
# Version: 4.0
# Updated: Edward Sung (edward.sung@gwu.edu) on 02/24/23

# Created by: Edward Sung (edward.sung@gwu.edu) on 11/02/22

# minimap2 outputs -asm20.paf files, which are then cleaned up, appended together into one dataframe and processed in summary.

# Summary Files/DataFrames - summary_df, threshold_count_df, presence_df, proportional_df, host_element_prevalence_df, element_presence_df(s).


# Work in Progress features:
# MapQ is an input variable to control thresholding


# Current minimap2_pipeline_vx.x.sh Inputs: python minimap2_output_processor.py (path_to_paf) (host_file.txt) (element_gene_names.txt) (output_file_names)

#%% Import Packages and Dependencies
# Packages
import pandas as pd
import numpy as np
import xlsxwriter
import os
import argparse


#%% Argument Parsers
parser = argparse.ArgumentParser()
parser.add_argument("dir_path", help="User provided directory path to the .paf data files")
parser.add_argument("host_file", help="User provided host file for genome references")
parser.add_argument("element_gene_names_file", help="Automatically provided file from pipeline for list of element gene names used in minimap2")
parser.add_argument("output_name", help="User provided output_file_name")
args = parser.parse_args()

dir_path = args.dir_path + "/"
host_file = args.host_file
element_gene_names_file = args.element_gene_names_file
output_name = args.output_name


#%% Testing Purposes
# os.chdir("/Users/edward.sung/Desktop/minimap2_testWork/BigFuti")
#
# dir_path = "paf_Files/"
# host_file = "BigFUTI_futimapALL_Updated_HostLabels.txt"
# element_gene_names_file = "element_genes_fasta_Names.txt"
# output_name = "minimap2_bigfuti_test_07262023"


#%% Locate .paf output files
# List Data Files, searches for -asm20.paf files
fileList = [file for file in os.listdir(dir_path) if file.endswith("-asm20.paf")]


#%% host_info_df DataFrame (For creating host label input file, column names are not important, but column position is important. First column are the Genome_Ref and the second column is Host ID.)
print("Importing Host Labels...")

host_info_df = pd.read_csv(host_file, sep="\t")
host_info_df.columns = ["Genome_Ref", "Host"]

# Utilize this to remove any exccessive filename extensions
#host_info_df = host_info_df[host_info_df['Genome_Ref'].isin([file.replace("_scaffolds-asm20.paf", "") for file in fileList])]
host_info_df = host_info_df[host_info_df['Genome_Ref'].isin([file.replace("-asm20.paf", "") for file in fileList])]

HostList = list(host_info_df.Host.unique())

# Adds Poultry as a host (PENDING Expansion to include multiple host/lists)
# Poultry - combination of Chicken and Turkey
poultryAdded = False
if all(host not in HostList for host in ["Poultry", "poultry"]): # Checks is Poultry or poultry (capitalization) exists in the HostList
    if all(host in HostList for host in ["Chicken", "Turkey"]): # Checks if Chicken AND Turkey exists in HostList. If do, create Poultry host, which will be used as a new group that is the sum of Chicken and Turkey data
        HostList.append("Poultry")
        poultryAdded = True

print("Host Labels imported.")


#%%
# Import Target Element Gene List used for minimap2 submission
print("Importing Target Element Gene List...")

ElementGeneList_file = open(element_gene_names_file, "r")
ElementGeneList_raw = ElementGeneList_file.read()
ElementGeneList_parsed = ElementGeneList_raw.split("\n")
ElementGeneList_cleaned = [ElementGene.strip(">") for ElementGene in ElementGeneList_parsed]
ElementGeneList_cleaned = list(filter(None, ElementGeneList_cleaned)) # Remove any empty lines
ElementGeneList_file.close()

print("Target Element Gene List imported.")


#%% summary_df, threshold_count_df and presence_df (Derived from rawData)
print("Creating summary_df, threshold_count_df and presence_df...")

# main_data (As a text file to be appended to, original method as a csv excel was too slow / too big to handle if dataset is too large)
main_data_df = pd.DataFrame(columns=["Element_Gene",
                                     "Num_Base_Matches",
                                     "Num_Full_Gap_Base_Matches", # `Num_Full_Gap_Base_Matches` is the full length including gaps
                                     "Alignment_Identity",
                                     "MapQ",
                                     "Genome_Ref",
                                     "Host"])

file_output_main = output_name + "_Main_Data.tsv" # main_data tsv that contains all minimap2 data
file_filtered_output_main = output_name + "_filtered_Main_Data.tsv" # filtered tsv that contains minimap2 data filtered out low mapq scores

# Creating both tsv files with the same headers
main_data_df.to_csv(file_output_main, sep='\t', index=False)
main_data_df.to_csv(file_filtered_output_main, sep='\t', index=False)

# summary_df dataframe setup
noData_summary = []
summary_dict = {}

# threshold_count_df dataframe setup
threshold_count_dict = {}
MapQ_threshold = 40  # To be implemented as a variable in the future
MapQ_threshold_colname = "MapQ>=" + str(MapQ_threshold) + "_Called_Count"

# presence_df dataframe setup
presence_dict = {}

# Loop through all of the genome files
for file in fileList:
    print("Processing: ", file)
    filepath = dir_path + file

    # Compiles the paf data into the dict
    Genome_Ref = file.replace("-asm20.paf", "") # Removes suffix to obtain genome reference name

    # Removes any additional suffixes
    #Genome_Ref = Genome_Ref.replace("_scaffolds", "")

    # Identifies the Host
    Genome_Host = host_info_df.loc[host_info_df["Genome_Ref"] == Genome_Ref, "Host"].values[0]

    # 0 hit paf files will have a file size of 0 (Also means all element_genes are not present)
    if os.stat(filepath).st_size == 0:

        # Fill in all data point as 0
        rawData_df = pd.DataFrame({"Element_Gene": ["No_Hits"],
                                   "Num_Base_Matches": [0],
                                   "Num_Full_Gap_Base_Matches": [0],
                                   "Alignment_Identity": [0],
                                   "MapQ": [0],
                                   "Genome_Ref": [Genome_Ref],
                                   "Host": [Genome_Host]})

        # Append the rawData to the on-going main_data tsv
        rawData_df.to_csv(file_output_main, mode='a', sep='\t', index=False, header=False)

        # summary_dict data
        summary_dict[Genome_Ref] = [0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    Genome_Host,
                                    "No_Hits"]

        # threshold_count_dict
        full_called_count = 0
        MapQ_called_count = 0
        called_difference = full_called_count - MapQ_called_count

        threshold_count_dict[Genome_Ref] = [full_called_count, MapQ_called_count, called_difference, len(ElementGeneList_cleaned)]

        # presence_dict
        presence_dict[Genome_Ref] = [0 for ElementGene in ElementGeneList_cleaned]

        # Collect all the genomes that are 0 hits paf files (To be calculated from summary_dict in the future Update)
        noData_summary.append(Genome_Ref)
    else:
        # Load in paf data
        rawData_df = pd.read_csv(filepath, sep="\t", header=None, usecols=[0, 9, 10, 11])
        rawData_df.columns = ["Element_Gene", "Num_Base_Matches", "Num_Full_Gap_Base_Matches", "MapQ"] # "usecols" selects these specific columns

        # Calculate Blast-like Alignment Identity
        rawData_df.insert(3,"Alignment_Identity", [Num_Base_Matches / Num_Full_Gap_Base_Matches for Num_Base_Matches, Num_Full_Gap_Base_Matches in zip(rawData_df["Num_Base_Matches"], rawData_df["Num_Full_Gap_Base_Matches"])])

        rawData_df["Genome_Ref"] = Genome_Ref
        rawData_df["Host"] = Genome_Host

        # Append the rawData to the on-going main_data tsv
        rawData_df.to_csv(file_output_main, mode='a', sep='\t', index=False, header=False)

        # Filtered version of on-going main_data tsv as filtered_main_data that filters out low mapq scores based on set threshold
        filtered_rawData_df = rawData_df[rawData_df["MapQ"] >= MapQ_threshold]
        filtered_rawData_df.to_csv(file_filtered_output_main, mode='a', sep='\t', index=False, header=False)

        # summary_dict data
        summary_dict[Genome_Ref] = [rawData_df["Alignment_Identity"].min(),
                                    rawData_df["Alignment_Identity"].max(),
                                    rawData_df["Alignment_Identity"].mean(),
                                    rawData_df["MapQ"].min(),
                                    rawData_df["MapQ"].max(),
                                    rawData_df["MapQ"].mean(),
                                    Genome_Host,
                                    "Hits"]

        # threshold_count_dict
        full_called_count = len(rawData_df) # Counts all of the element_genes called by minimap2
        MapQ_called_count = len(rawData_df[rawData_df["MapQ"] >= MapQ_threshold]) # Threshold cutoff called element_genes by the MapQ score
        called_difference = full_called_count - MapQ_called_count

        threshold_count_dict[Genome_Ref] = [full_called_count, MapQ_called_count, called_difference, len(ElementGeneList_cleaned)]

        # presence_dict
        # Selects data filtered at MapQ value and above
        presence_dict[Genome_Ref] = [1 if ElementGene in list(rawData_df[rawData_df["MapQ"] >= MapQ_threshold].Element_Gene) else 0 for ElementGene in ElementGeneList_cleaned]


# dict to dataframe function
def dict_to_df(dict_input, colnames_input): # colnames_input is a list of column names
    # Function converts dict to dataframe with appropriate column names
    df = pd.DataFrame.from_dict(dict_input, orient = "index")
    df.reset_index(inplace=True)
    df.columns = colnames_input
    return df

# summary_df
summary_df_colnames = ["Genome_Ref", "Alignment_Identity_Min", "Alignment_Identity_Max", "Alignment_Identity_Mean", "MapQ_Min", "MapQ_Max", "MapQ_Mean", "Host", "Query_Hits"]
summary_df = dict_to_df(summary_dict, summary_df_colnames)

# summary_df Overview
samples_summary_total = len(fileList)
elementGenes_summary_total = len(ElementGeneList_cleaned)
noData_summary_total = len(noData_summary)
samples_analyzed_summary_total = samples_summary_total - noData_summary_total

summary_overview_df = pd.DataFrame({"Stats": ["Total Number of Genomes",
                                              "Total Number of Genomes with Hits",
                                              "Total Number of Genomes with No Hits",
                                              "Total Number of Element Genes Screened"],
                                    "Count": [samples_summary_total,
                                              samples_analyzed_summary_total,
                                              noData_summary_total,
                                              elementGenes_summary_total]})

print("summary_df created.")

# threshold_count_df
threshold_count_df_colnames = ["Genome_Ref", "Full_Called_Count", "MapQ>=40_Called_Count", "Difference", "Total_Element_Genes"]
threshold_count_df = dict_to_df(threshold_count_dict, threshold_count_df_colnames)
print("threshold_count_df created.")

# >>>> Further analysis utilizes the MapQ_threshold subset data <<<<
print("Note: All further analysis and dataframes uses the MapQ_threshold subset data")

# presence_df
presence_df_colnames = ElementGeneList_cleaned.copy() # Copy ElementGeneList to insert Element_Gene name into the list for column names
presence_df_colnames.insert(0, "Element_Gene")
presence_df_raw = dict_to_df(presence_dict, presence_df_colnames)
presence_df = presence_df_raw.transpose(copy=True)
presence_df.reset_index(inplace=True)
presence_df.columns = presence_df.iloc[0]
presence_df.drop(index=0, inplace=True)
presence_df.reset_index(drop=True, inplace=True)
print("presence_df created.")


#%% proportional_df and host_element_prevalence_df based on Host Groups (Derived from presence_df)
print("Creating proportional_df and host_element_prevalence_df...")

# initalize proportional_df
proportional_df = pd.DataFrame()

# initalize host_element_prevalence_df
host_element_prevalence_df = pd.DataFrame(presence_df["Element_Gene"].str.split("_").str[0].value_counts())
host_element_prevalence_df.reset_index(inplace=True)
host_element_prevalence_df.columns = ["Element", "total no.of gene in element"]

for host in HostList:
    if host == "Poultry" and poultryAdded: # This is true if we add the Poultry host, else if Poultry already existed, will be treated as a stand alone host like the other hosts
        # Combines all of the Chicken and Turkey genomes as one list
        chicken_ref_genomes = list(host_info_df[host_info_df.Host == "Chicken"].Genome_Ref)
        turkey_ref_genomes = list(host_info_df[host_info_df.Host == "Turkey"].Genome_Ref)
        host_ref_genomes = chicken_ref_genomes + turkey_ref_genomes
    else:
        host_ref_genomes = list(host_info_df[host_info_df.Host == host].Genome_Ref)

    # Totals up the number of genomes (pior to adding Element_Gene column)
    total_host_ref_genomes = len(host_ref_genomes)

    # Adds in Element_Gene to keep column in subset data
    host_ref_genomes.append("Element_Gene")

    # Filter (Intersect) presence_df by host_ref_genomes to have a presence_df data containing only respective host genomes, then sum each row
    host_prop_df = pd.DataFrame(presence_df[presence_df.columns.intersection(host_ref_genomes)].set_index("Element_Gene").sum(axis=1))
    host_prev_df = pd.DataFrame(presence_df[presence_df.columns.intersection(host_ref_genomes)])

    # proportional_df
    # Column Names
    host_Num_Genome_Refs_Called = host + "_Num_Genome_Refs_Called"
    host_Total_Num_Genome_Refs = host + "_Total_Num_Genome_Refs"
    host_Proportional_Called = host + "_Proportional_Called"

    host_prop_df.rename(columns={0 : host_Num_Genome_Refs_Called}, inplace=True)
    host_prop_df[host_Total_Num_Genome_Refs] = total_host_ref_genomes

    # Calculate the proportional abundance per element gene
    host_prop_df[host_Proportional_Called] = host_prop_df[host_Num_Genome_Refs_Called] / total_host_ref_genomes * 100

    # Concat prop data to proportional_df
    proportional_df = pd.concat([proportional_df, host_prop_df], axis=1)

    # host_element_prevalence_df
    host_prev_df["Element"] = host_prev_df["Element_Gene"].str.split("_").str[0] # Extract Element
    host_prev_df.drop("Element_Gene", axis=1, inplace=True)
    host_prev_df_sum = host_prev_df.groupby("Element").sum() # Sum up all genes per element

    # Convert numbers to be 1 or 0 for called or not called Elements for each genome
    host_prev_df_called = host_prev_df_sum.where(~(host_prev_df_sum > 0), 1)

    host_prev_df_called["Genomes_Sum"] = host_prev_df_called.sum(axis=1) # Sum across the row (Element)
    host_prev_df_called.reset_index(inplace=True)

    host_name_N = host + "__N=" + str(total_host_ref_genomes)
    host_prev_df_called[host_name_N] = [val / total_host_ref_genomes * 100 for val in host_prev_df_called["Genomes_Sum"]]
    host_prev_df_ToMerge = host_prev_df_called[["Element", host_name_N]]

    host_element_prevalence_df = pd.merge(host_element_prevalence_df, host_prev_df_ToMerge, how="left", on="Element")

# Reindex proportional_df for formatting purposes
proportional_df.reset_index(inplace=True)

print("proportional_df created.")
print("host_element_prevalence_df created.")


#%% element_presence_df DataFrame, formatted to be input file for hostelement_blca.R (Derived from presence_df)
print("Creating element_presence_df(s)...")

# Elements List and Column name for df in function below
eleList = sorted(presence_df["Element_Gene"].str.split("_").str[0].unique()) # Apply sorted to keep elements order standardized
eleList.insert(0, "Genome_Ref")

# Genomes List
genomes = presence_df.columns.drop("Element_Gene")

# Element Presence DataFrame (Based off of presence_df)
ele_presence_df = presence_df.copy()
ele_presence_df["Element"] = ele_presence_df["Element_Gene"].str.split("_").str[0]
ele_presence_df["Gene"] = ele_presence_df["Element_Gene"].str.split("_").str[1:].apply(lambda x: "_".join((x)))
ele_presence_df.insert(1, "Element", ele_presence_df.pop("Element"))
ele_presence_df.insert(2, "Gene", ele_presence_df.pop("Gene"))

# Elements Value Count
ele_total_genes = ele_presence_df["Element"].value_counts().sort_index() # value_counts sorts by values, but want to sort by index to match up with groupby in element_presence_df function

def element_presence_df(threshold_val):
    # Function creates the element_presence_df at threshold_val and then transposes into appropriate format

    # Initialize df
    df_dict = {}

    for genome in genomes:
        # Sum up the called Genes for each Element per Genome, sort by index to standardize
        ele_df_gene_count = ele_presence_df.groupby("Element")[genome].sum().sort_index()

        # Calculate the called proportion for each element
        ele_prop = [gene_count / total_genes for gene_count, total_genes in zip(ele_df_gene_count, ele_total_genes)]

        if threshold_val == 0: # Difference is there is no equal sign for boolean, to signify any prop value is present at anything above 0
            df_dict[genome] = [1 if prop > threshold_val else 0 for prop in ele_prop]
        else:
            df_dict[genome] = [1 if prop >= threshold_val else 0 for prop in ele_prop]

    # Transform df_dict into df
    df = dict_to_df(df_dict, eleList)


    # Transpose and Re-Format into BLCM input format (OLD Format)
    df_T = df.copy()

    df_T = df_T.T
    df_T.reset_index(inplace=True)
    df_T = df_T.rename(columns=df_T.iloc[0]).drop(df_T.index[0]).reset_index(drop=True)
    df_T.rename(columns={"Element": "Sample_Name"}, inplace=True)

    return df_T


# Create the element_presence_df (Variables can be created and adjusted as needed), To be as an input in future
element_presence_dict = {"any_element_presence_df" : ["any", 0],
                         "twentyfive_element_presence_df" : ["twentyfive", 0.25],
                         "thitythree_element_presence_df" : ["thitythree", 0.33],
                         "fifty_element_presence_df" : ["fifty", 0.50]}

element_presence_List = []
for threshold_name, threshold_value in element_presence_dict.items():
    element_presence_List.append((threshold_value[0], element_presence_df(threshold_value[1])))
    print(threshold_name + " created.")


#%% Exporting DataFrames
print("Exporting data...")

# Main_Data Excel
file_output_main = output_name + "_Main_Data.xlsx"
wb = pd.ExcelWriter(file_output_main, engine='xlsxwriter')

summary_df.to_excel(wb, sheet_name="Summary_Data")
summary_overview_df.to_excel(wb, sheet_name="Summary_Data", index=False, startcol=11)
threshold_count_df.to_excel(wb, sheet_name='Threshold_Count_Data')
presence_df.T.to_excel(wb, sheet_name='Presence_Data') # presence_df is last step tranposed to put samples into row for it to fit into excel limitaions (Max sheet size is: 1048576, 16384)
proportional_df.to_excel(wb, sheet_name='Proportional_Data')
host_element_prevalence_df.to_excel(wb, sheet_name='Host_Element_Prevalence')

wb.save()
print("Main_Data exported.")

# Element_Presence DataFrames at thresholds
for element_presence in element_presence_List:
    element_presence_output_name = output_name + "_" + element_presence[0] + "_element_presence.tsv"
    element_presence[1][0].T.to_csv(element_presence_output_name, sep='\t', index=True) # element_presence dfs are last step tranposed to put samples into row for it to fit into excel limitaions (Max sheet size is: 1048576, 16384)
    print(element_presence_output_name + " exported.")

print("All Data exported.")
print("minimap2_output_processor.py script complete.")
