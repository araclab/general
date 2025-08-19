#!/bin/bash

# This script is to be used for Edward's (edward.sung@gwu.edu) slurm array scripts.
# It adds the indexing numbers and "__@__" separator/identifier in front of each sample name in the sample list.
# The slurm array scripts uses these indexing numbers associates to a slurm task ID call and parses out the file name.

# Created by Edward Sung (edward.sung@gwu.edu) on 2/14/2023

# User Inputs
sampleList_input=$1

# Adds two indexes (first number tracks set per 1000, second number tracks the sample in the set (1-1000) to the start of each row for the sample names
sampleList_filename=${sampleList_input%.*}
Slurm_MaxArraySize=1000

# i is the set index for groups of 1000s
i=0

# j is the sample index ranging from 1 up to 1000 per set index
j=1

# Initialize SLURM-ARRAY-READY.txt file
touch ${sampleList_filename}_SLURM-ARRAY-READY.txt

while read -r line
do
   # Appends my indexies to the file names in the provided sample list 
   str="${i}__@__${j}__@__${line}"
   echo $str >> ${sampleList_filename}_SLURM-ARRAY-READY.txt
 
   if [ $j -lt $Slurm_MaxArraySize ]
   then
      ((j+=1)) # increments j by 1 until 1000
   else
      ((i+=1)) # increments set index by 1
      j=1 # resets the j indexing back to 1 after hitting 1000
   fi
done < $sampleList_input

echo "Indexing numbers and __@__ has been appended to each line in the sample list."
echo "${sampleList_filename}_SLURM-ARRAY-READY.txt is ready, thank you!"
