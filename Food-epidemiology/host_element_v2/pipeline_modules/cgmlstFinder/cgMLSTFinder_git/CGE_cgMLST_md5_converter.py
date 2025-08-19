#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This script is a helper for the CGE cgMLST.py.
# https://bitbucket.org/genomicepidemiology/cgmlstfinder/src/master/
# This utilizes the output file from cgMLST.py - ecoli_results.txt and each respective kma_*_.fsa file to convert allele calls into md5 calls.

# Note - this is designed for cgMLST - ecoli for now

# Developed by Edward (G37543428) on 1/30/24


# Packages
import os
import argparse
import pandas as pd
from Bio import SeqIO
import hashlib

# %% Argument Parsers
parser = argparse.ArgumentParser()
parser.add_argument("working_dir")
parser.add_argument("results_file")
parser.add_argument("kma_fsa_file")
args = parser.parse_args()

os.chdir(args.working_dir)
results_file_input = args.results_file
kma_fsa_file_input = args.kma_fsa_file

#%% Testing Purposes
# os.chdir("/Users/edward.sung/Desktop/Projects/DockerStuff/CGE_Tools/cgmlstfinder/TestingDirectory/TestFolder")
#
# results_file_input = "ESC_GA3724AA_AS/ecoli_results.txt"
# kma_fsa_file_input = "ESC_GA3724AA_AS/kma_ESC_GA3724AA_AS.fsa"

#%%
cgmlst_results = pd.read_csv(results_file_input, sep="\t")
fasta_dict = SeqIO.index(kma_fsa_file_input, "fasta")

md5_return_List = [cgmlst_results["Genome"][0]]

allele_List = cgmlst_results.columns.drop("Genome")

for allele in allele_List:
    # if cgMLST identifes "-", this is kept because its not a new allele, but not in database either
    if cgmlst_results[allele][0] == "-":
        md5_return = hashlib.md5(str(cgmlst_results[allele][0]).encode("utf-8")).hexdigest()

    # if cgMLST identifies new allele, it already returns it as md5, keep this in the conversion
    elif len(str(cgmlst_results[allele][0])) == 32:
        md5_return = cgmlst_results[allele][0]

    # else find the fasta sequence identified by kma for that allele and convert it to md5
    else:
        fasta_name = str(allele) + "_" + str(cgmlst_results[allele][0])
        md5_return = hashlib.md5(str(fasta_dict[fasta_name].seq).encode("utf-8")).hexdigest()

    md5_return_List.append(md5_return)

md5_return_output = "\t".join(md5_return_List)

#%%
# Strict output call as a text file for script reading
md5_return_output_file = open("ecoli_results_md5_conversion.txt", "w")
md5_return_output_file.write("\t".join(cgmlst_results.columns) + "\n" +
                             md5_return_output + "\n")
md5_return_output_file.close()
