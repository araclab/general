#!/bin/sh

# Shell script that submits SlurmArray batches (cgmlstFinder_submitter.sh) that runs cgmlstFinder analysis (cgmlstFinder_runner.sh).

# Developed by Edward Sung (edward.sung@gwu.edu) on 2/20/24

# Version v1

# Run script using: bash run_cgmlstFinder.sh (fasta_folder_input) (fasta_sampleList_input) (job_name)



# Script Locations
cgmlstfinder_scripts="/YOUR/FILE/PATH/HERE/cgmlstFinder/"



# User Inputs
fasta_folder_input=$1
fasta_sampleList_input=$2
job_name=$3




# Error for required number of inputs
if [ $# -lt 3 ]
then
        echo "Please give all 3 arugments: (fasta_folder_input) (fasta_sampleList_input) (job_name)"
        exit 1
fi

# Names the slurm job, as well as used in the singleton dependency
jobname=${job_name}_cgmlstfinder

# Start-Up / Preparations
# Convert sample list to SLURM-ARRAY-READY format: appends indexing and __@__ to each sample name in file
$cgmlstfinder_scripts/slurmArray_SampleList_Modifier.sh $fasta_sampleList_input
sampleList_filename=${fasta_sampleList_input%.*}
echo 
echo



# Create File System
mkdir cgmlstfinder_output
mkdir cgmlstfinder_output/kmodes_ready
mkdir slurmFiles
mkdir slurmFiles/scripts
mkdir slurmFiles/slurm_outputs


cp $cgmlstfinder_scripts/kmodes_ready_inputfile_TEMPLATE.txt cgmlstfinder_output/kmodes_ready/kmodes_ready_inputfile.txt



# Run Slurm Array Settings
numFiles=$(cat ${sampleList_filename}_SLURM-ARRAY-READY.txt | wc -l)
Slurm_MaxArraySize=1000

# Calculates the SlurmJobArray parallel submissions
if (( $numFiles % $Slurm_MaxArraySize == 0 ))
then
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize`
else
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize + 1` # This is a ceiling int calculation
fi

# Most used nodes 12, minimum is 1, it will only use 1 if its submits more than 6 batches
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

# Manually Set Slurm_CalcRunParallel for this special case (to speed up process) -----------------------
Slurm_CalcRunParallel=2


# Splits up the sample list by index_set and runs the slurmjobarray batches based on the start and end of each set
for ((i=0; i<$Slurm_chunks; i++))
do
   # Tracks the index_set number for the sample list (First number)
   index_set=$i

   array_start="$(cat ${sampleList_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
   array_end="$(cat ${sampleList_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"
   
   echo "sbatch --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} -J $jobname $cgmlstfinder_scripts/cgmlstFinder_submitter.sh $fasta_folder_input ${sampleList_filename}_SLURM-ARRAY-READY.txt $index_set"
   sbatch --array=$array_start-$array_end%$Slurm_CalcRunParallel -J $jobname $cgmlstfinder_scripts/cgmlstFinder_submitter.sh $fasta_folder_input ${sampleList_filename}_SLURM-ARRAY-READY.txt $index_set
done

# Compile and Clean-up file system script
sbatch --dependency=singleton -J $jobname $cgmlstfinder_scripts/cgmlstFinder_compile.sh cgmlstfinder_output/ $fasta_sampleList_input $sampleList_filename
