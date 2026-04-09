#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p project
#SBATCH -e cgmlstFinder_Submitter_%j.err
#SBATCH -o cgmlstFinder_Submitter_%j.out


# NOTE: This is a modified script from https://github.com/araclab/general/tree/main/Food-epidemiology/host_element_v2
# modified version author: Jon Sztuk Slotved 
# email: JOSS@ssi.dk

# How to Submit jobs (Use Sbatch if cloud computing):
# bash cgmlstFinder_Submitter.sh (Data_Folder_input) (Data_Folder_Samplelist_input) (Job_Name_input)
	# Data_Folder_input -- folder containings all of the fasta assemblies
	# Data_Folder_Samplelist_input -- text file, with each line being the sample/filename from the Data_Folder_Input
	# Job_Name_input -- names the output folder and slurm jobs



# Script Locations (Path to where all slurm-array scripts live, use `pwd` to find path.

# User Inputs
Data_Folder_input=$1
Data_Folder_Samplelist_input=$2
Job_Name_input=$3
partition=${4:-project}
config_file=$5

project_root=$(grep '^GLOBAL__PROJECT_ROOT__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
Slurm_Array_scripts="$project_root/pipeline_modules/cgmlstFinder"




# Error for required number of inputs
if [ $# -lt 3 ]
then
   echo "Please give all 3 arugments: (Data_Folder_input) (Data_Folder_Samplelist_input) (Job_Name_input)"
   exit 1
fi

CGE_DB_Path=$(grep '^CGE__DB_PATH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
CGE_KMA_Path=$(grep '^CGE__KMA_PATH__=' "$config_file" | awk -F'__=' '{print $2}' | xargs)
for check_path in "$project_root" "$CGE_DB_Path" "$CGE_KMA_Path"; do
   if [ -z "$check_path" ] || [ ! -e "$check_path" ]; then
      echo "ERROR: required path not found or missing from config: $check_path"
      exit 1
   fi
done

echo "found: $(ls $Data_Folder_input | wc -l) fasta files"

# Names the slurm job, as well as used in the singleton dependency
jobname=${Job_Name_input}


# Create File System
mkdir ${Job_Name_input}_output
mkdir ${Job_Name_input}_output/processing_files
mkdir ${Job_Name_input}_output/slurm_out

#move slurm output
if [ -n "$SLURM_JOB_ID" ]; then
   mv cgmlstFinder_Submitter_${SLURM_JOB_ID}.out ${Job_Name_input}_output/slurm_out
   mv cgmlstFinder_Submitter_${SLURM_JOB_ID}.err ${Job_Name_input}_output/slurm_out
fi


# Start-Up / Generate SLURM-ARRAY-READY samplelist
# Convert samplelist to SLURM-ARRAY-READY format: appends indexing and __@__ to each sample name in file. 
#Below automatically runs Slurm_Array_sampleListReady.sh script to handle the formatting
$Slurm_Array_scripts/Slurm_Array_SampleListReady.sh $Data_Folder_Samplelist_input $Job_Name_input
samplelist_filename=${Data_Folder_Samplelist_input%.*} # Strip extensions
echo 
echo


# Slurm Array Settings
# numFiles = the numeric of the amount of lines in the SLURM-ARRAY-READY.txt file
numFiles=$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | wc -l) # Gets the total number of samples/files
#number of samples runnable for each node
Slurm_MaxArraySize=1000 # Maximum HPC MaxArraySize

# Calculates the SlurmJobArray parallel submissions
# if modulo returns 0, add slurmchunks = 
if (( $numFiles % $Slurm_MaxArraySize == 0 ))
then
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize`
else
   # works because "expr" always rounds down, so fx. 800/1000 is 0.8, rounded down to 0 and then we add 1, meaning 1 slurm chunk
   Slurm_chunks=`expr $numFiles / $Slurm_MaxArraySize + 1` # This is a ceiling int calculation
fi

# Most used nodes 12, minimum is 1, it will only use 1 if its submits more than 6 batches
# Please adjust these numbers accordingly to your specifications or HPC needs
# Example: if samplelist contains 1000 files, it will submit 1 SlurmArray job that will run use 12 compute nodes at a time.
# Example: if samplelist contains 10000 files, it will submit 10 SlurmArray jobs that will run only 1 compute node per SlurmArray job at a time.

#since 12 compute nodes are available, we split them most effectively as following
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
#Slurm_CalcRunParallel=2


# Splits up the samplelist by index_set and runs the SlurmArray jobs based on the start and end of each set
for ((i=0; i<$Slurm_chunks; i++)) # loop, starting at 0, condition is i > Slurm_chunks (stops if not true) and then iterating by 1 (i++)
do
   # Tracks the index_set number for the samplelist (First number)
   index_set=$i

   # Identifes the start and end of the array to be submitted 
   
   array_start="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | head -1 | awk -F "__@__" '{print $2}')"
   array_end="$(cat ${samplelist_filename}_SLURM-ARRAY-READY.txt | grep "^${i}__" | tail -1 | awk -F "__@__" '{print $2}')"
   
   # Submit the jobs to HPC
   echo "sbatch -p $partition --array=${array_start}-${array_end}%${Slurm_CalcRunParallel} -J $jobname $Slurm_Array_scripts/cgmlstFinder_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output $config_file"
   sbatch -p $partition --array=$array_start-$array_end%$Slurm_CalcRunParallel -J $jobname $Slurm_Array_scripts/cgmlstFinder_Runner.sh $Data_Folder_input ${samplelist_filename}_SLURM-ARRAY-READY.txt $index_set ${Job_Name_input}_output "$config_file"
done

#compile the results data and Clean-up file system script
compiler_jid=$(sbatch --parsable --dependency=singleton -p $partition -J $jobname $Slurm_Array_scripts/cgmlstFinder_Compiler.sh ${Job_Name_input}_output $jobname ${samplelist_filename}_SLURM-ARRAY-READY.txt "$config_file")

echo "---------- Your jobs have been submitted to HPC, thank you. ----------"
echo "$compiler_jid"
