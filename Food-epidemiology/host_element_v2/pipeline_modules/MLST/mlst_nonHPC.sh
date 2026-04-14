#!/bin/sh
# Script Developed by: Maliha Aziz (araclab@gwu.edu) on 03/23/26

# bash mlst_nonHPC.sh (Data_Folder_input) (Data_Folder_Samplelist_input)
        # Fasta_Folder_input -- folder containings all of the fasta assemblies
        # Output_folder_name -- Output folder name
        # mlst_db --  MLST database species

# Make sure your CGE envrionement is activated
# load CLI Blast


# PATHS
cge_mlst_git="PATH TO MLST scripts folder/mlst"
mlst_db_dir="PATH TO MLST DB folder/mlst_db/"
CGE_kma_tools="PATH TO KMA/kma"  


# User Inputs
Data_Folder_input=$1
Out_folder_name=$2
mlst_db=$3

# Error for required number of inputs
if [ $# -lt 3 ]
then
    echo "Please give all 2 arugments: (Fasta_Folder_input) (Out_folder_name) (mlst_db)"
   exit 1
fi

mkdir ${Out_folder_name}
cd ${Out_folder_name}
# Compile mlst calls
echo -e "SampleID\tMLST" > mlst_calls.txt

for filepath in "$Data_Folder_input"/*.*; do
    fileInput=$(basename "$filepath")
    filename="${fileInput%%.*}"
    echo "$filename"
    mkdir $filename
   # Run mlstFinder
   python3 $cge_mlst_git/mlst.py -i ${Data_Folder_input}/$fileInput -o $filename -s $mlst_db -p $mlst_db_dir  -x -matrix

   # Collect Results
   cat $filename/results.txt | grep "Sequence Type" | awk -F': ' '{print $2}' > tmpfile
   sed -i "1s/^/$filename\t/" tmpfile
   cat tmpfile >> mlst_calls.txt

done 
