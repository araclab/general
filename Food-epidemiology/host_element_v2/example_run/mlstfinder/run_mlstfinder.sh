#!/bin/sh
#SBATCH --time 30:00
#SBATCH -p nano
#SBATCH -e mlstfinder_%j.err
#SBATCH -o mlstfinder_%j.out
#SBATCH -J mlstfinder

# This script runs only mlstFinder from CGE Tools.
# Source: https://bitbucket.org/genomicepidemiology/mlst/src/master/
# Database: https://bitbucket.org/genomicepidemiology/mlst_db/src/master/

# Script Developed by: Edward Sung (edward.sung@gwu.edu) on 02/14/24



# Script Updated by: Edward Sung (edward.sung@gwu.edu) on 04/30/25
# Fixed file paths to scratch
# Updated file structure





STARTTIMER="$(date +%s)"

# Pegasus Conda Enviroment
. /GWSPH/groups/liu_price_lab/tools/anaconda3/etc/profile.d/conda.sh
conda activate cge_tools_env

# Pegasus Modules
module load blast+/2.16.0+


# PATHS
cge_mlst_git="/scratch/liu_price_lab/ehsung/github/Development/ehsung/microbiome/CGE_tools/1_database/mlst_git/mlst"
mlst_db="/scratch/liu_price_lab/ehsung/databases/mlst_db/mlst_db/"
CGE_kma_tools="/scratch/liu_price_lab/ehsung/databases/kma/kma"  # NEED TO DEBUG KMA


# User Inputs
rawData_folder=$1
rawData_fileList=$2
db_type=$3
jobname=$4

# Make file system
mkdir ${jobname}_output
mkdir ${jobname}_output/processing_files
mkdir ${jobname}_output/compiled_files
mkdir ${jobname}_output/slurmFiles
mkdir ${jobname}_output/mlst_tmpdir




# Compile mlst calls
echo -e "SampleID\tMLST" > ${jobname}_output/compiled_files/${jobname}_mlst_calls.txt


while read -r line
do
   # strip for filename
   filename=${line%.*}

   # create own folder
   mkdir ${jobname}_output/processing_files/$filename

   # Run mlstFinder
   python3 $cge_mlst_git/mlst.py -i $rawData_folder/$line -o ${jobname}_output/processing_files/$filename -s $db_type -p $mlst_db -t ${jobname}_output/mlst_tmpdir -x -matrix

   # Collect Results
   cat ${jobname}_output/processing_files/$filename/results.txt | grep "Sequence Type" | awk -F': ' '{print $2}' > tmpfile
   sed -i "1s/^/$filename\t/" tmpfile
   cat tmpfile >> ${jobname}_output/compiled_files/${jobname}_mlst_calls.txt

done < $rawData_fileList


# Cleanup file system
rm tmpfile
rmdir ${jobname}_output/mlst_tmpdir

mv mlstfinder_${SLURM_JOB_ID}.err ${jobname}_output/slurmFiles
mv mlstfinder_${SLURM_JOB_ID}.out ${jobname}_output/slurmFiles




# Script Timer
ENDTIMER="$(date +%s)"
DURATION=$[${ENDTIMER} - ${STARTTIMER}]
HOURS=$((${DURATION} / 3600)) 
MINUTES=$(((${DURATION} % 3600)/ 60))
SECONDS=$(((${DURATION} % 3600) % 60))

echo "RUNTIMER: $HOURS:$MINUTES:$SECONDS (hh:mm:ss)"
