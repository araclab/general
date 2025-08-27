#!/bin/sh


# How to Submit jobs:
# bash cgmlstFinder_Submitter.sh (Data_Folder_input) (Data_Folder_Samplelist_input) (Job_Name_input)
	# Data_Folder_input -- folder containings all of the fasta assemblies
	# Data_Folder_Samplelist_input -- text file, with each line being the sample/filename from the Data_Folder_Input
	# Job_Name_input -- names the output folder and slurm jobs



# Script Locations (Path to where all slurm-array scripts live, use `pwd` to find path.
Slurm_Array_scripts="/scratch/liu_price_lab/ehsung/github/paper_shared_gits/general/Food-epidemiology/host_element_v2/pipeline_modules/cgmlstFinder"



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
$Slurm_Array_scripts/Slurm_Array_SampleListReady.sh $Data_Folder_Samplelist_input
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


# Splits up the samplelist by index_set and runs the SlurmArray jobs based on the start and end of each set
for ((i=0; i<$Slurm_chunks; i++))
do
   # Tracks the index_set number for the samplelist (First number)
   index_set=$i

   # Identifes the start and end of the array to be submitted
   array_start="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
   array_end="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"
   
   # Submit the jobs to HPC
   echo "sbatch --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} -J $jobname $Slurm_Array_scripts/cgmlstFinder_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output"
   sbatch --array=$array_start-$array_end%$Slurm_CalcRunParallel -J $jobname $Slurm_Array_scripts/cgmlstFinder_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output
done

# Compile the results data and Clean-up file system script
sbatch --dependency=singleton -J $jobname $Slurm_Array_scripts/cgmlstFinder_Compiler.sh ${Job_Name_input}_output $jobname

echo "---------- Your jobs have been submitted to HPC, thank you. ----------"
