#!/bin/bash

# Created by Edward Sung (edward.sung@gwu.edu) on
# Version v1


# Script Locations (Path to where all slurm-array scripts live, use `pwd` to find path.
Slurm_Array_scripts="/Users/B328695/Documents/GitHub/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules_nonessential/fimHtyper/fimHtyper_local"

# User Inputs
Data_Folder_input=$1
Data_Folder_Samplelist_input=$2
Job_Name_input=$3


# Error for required number of inputs
if [ $# -lt 3 ]
then
   echo "Please give all 3 arugments: (Data_Folder_input) (Data_Folder_Samplelist_input) (Job_Name_input)"
   exit 1
fi


# Start-Up / Generate SLURM-ARRAY-READY samplelist
# Convert samplelist to SLURM-ARRAY-READY format: appends indexing and __@__ to each sample name in file
bash $Slurm_Array_scripts/Loca_fimH_SampleListReady.sh $Data_Folder_Samplelist_input
samplelist_filename=${Data_Folder_Samplelist_input%.*} # Strip extensions
echo 
echo


# Create File System
mkdir ${Job_Name_input}_output
mkdir ${Job_Name_input}_output/processing_files


# Slurm Array Settings
numFiles=$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | wc -l) # Gets the total number of samples/files
Slurm_MaxArraySize=1000 # Maximum HPC MaxArraySize

# Calculates the SlurmJobArray parallel submissions
if (( $numFiles % $Slurm_MaxArraySize == 0 ))
then
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize`
else
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize + 1` # This is a ceiling int calculation
fi

# Most used nodes 12, minimum is 1, it will only use 1 if its submits more than 6 batches
# Please adjust these numbers accordingly to your specifications or HPC needs
# Example: if samplelist contains 1000 files, it will submit 1 SlurmArray job that will run use 12 compute nodes at a time.
# Example: if samplelist contains 10000 files, it will submit 10 SlurmArray jobs that will run only 1 compute node per SlurmArray job at a time.
if [ $Slurm_chunks == 1 ]
then
   Slurm_CalcRunParallel=12

elif [ $Slurm_chunks == 2 ]
then
   Slurm_CalcRunParallel=6

elif [ $Slurm_chunks == 3 ]
then
   Slurm_CalcRunParallel=4

elif [ $Slurm_chunks == 4 ]
then
   Slurm_CalcRunParallel=3

elif [ $Slurm_chunks == 5 ]
then
   Slurm_CalcRunParallel=2

elif [ $Slurm_chunks == 6 ]
then
   Slurm_CalcRunParallel=2

else
   Slurm_CalcRunParallel=1
fi

# Manually Set Slurm_CalcRunParallel for this special case (to speed up process)
# If you need to speed-up the process, you can manually select the number of nodes to be used per SlurmArray job.
# Uncomment (delete the #) and type in your int number.
# Slurm_CalcRunParallel=5


# Splits up the samplelist by index_set and runs jobs locally based on the start and end of each set
for ((i=0; i<$Slurm_chunks; i++))
do
   # Tracks the index_set number for the samplelist (First number)
   index_set=$i

   # Identifes the start and end of the array to be submitted
   array_start="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
   array_end="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"
   
   # Run locally
   for ((task_id=array_start; task_id<=array_end; task_id++))
   do
      echo "bash $Slurm_Array_scripts/Loca_fimH_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output $task_id"
      bash $Slurm_Array_scripts/Loca_fimH_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output $task_id
   done
done

# Compile the results data and clean up file system
bash $Slurm_Array_scripts/Loca_fimH_Complier.sh ${Job_Name_input}_output

echo "---------- Local jobs completed, thank you. ----------"
