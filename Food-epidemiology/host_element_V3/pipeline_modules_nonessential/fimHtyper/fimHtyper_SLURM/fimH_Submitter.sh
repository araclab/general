#!/bin/bash

# created by Jon slotved

#config
config_file="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/config/config.env"

# Script Locations (Path to where all slurm-array scripts live, use `pwd` to find path.
Slurm_Array_scripts=$(grep "^FIMHTYPER__SLURM_SCRIPTS__=" "$config_file" | awk -F'__=' '{print $2}')

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


# Names the slurm job, as well as used in the singleton dependency
jobname=${Job_Name_input}


# Start-Up / Generate SLURM-ARRAY-READY samplelist
# Convert samplelist to SLURM-ARRAY-READY format: appends indexing and __@__ to each sample name in file
bash $Slurm_Array_scripts/Slurm_Array_SampleListReady.sh $Data_Folder_Samplelist_input
samplelist_filename=${Data_Folder_Samplelist_input%.*} # Strip extensions
echo 
echo


# Create File System
mkdir ${Job_Name_input}_output
mkdir ${Job_Name_input}_output/processing_files


# SLURM array settings
numFiles=$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | wc -l) # Total number of samples
Slurm_MaxArraySize=1000 # Maximum number of tasks allowed in one array job

# Calculate how many array jobs are needed
if (( $numFiles % $Slurm_MaxArraySize == 0 ))
then
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize`
else
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize + 1` # Round up to the next whole number
fi

# Set how many tasks to run at the same time for each array job
# Adjust these values to match your cluster setup
# Example: if the sample list has 1000 files, it submits 1 array job and runs up to 12 tasks at once.
# Example: if the sample list has 10000 files, it submits 10 array jobs and runs 1 task at once for each job.
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


# Splits up the samplelist by index_set and runs the SlurmArray jobs based on the start and end of each set
for ((i=0; i<$Slurm_chunks; i++))
do
   # Tracks the index_set number for the samplelist (First number)
   index_set=$i

   # Identifes the start and end of the array to be submitted
   array_start="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
   array_end="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"
   
   # Submit the jobs to HPC
   echo "sbatch --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} -J $jobname $Slurm_Array_scripts/fimH_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output"
   sbatch --array=$array_start-$array_end%$Slurm_CalcRunParallel -J $jobname $Slurm_Array_scripts/fimH_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output
done

# Compile the results data and Clean-up file system script
sbatch --dependency=singleton -J $jobname $Slurm_Array_scripts/fimH_Compiler.sh ${Job_Name_input}_output ${Job_Name_input}_output/compiled_results $samplelist_filename

echo "---------- Your jobs have been submitted to HPC, thank you. ----------"
