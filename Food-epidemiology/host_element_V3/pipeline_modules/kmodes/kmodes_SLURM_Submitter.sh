#!/bin/sh

#paths
kmodes_loc="/dpssi/data/Projects/mtg_host_elements_files_and_output/proj/general_JonThesis/Food-epidemiology/host_element_V3/pipeline_modules/kmodes"

#input
kmodes_rdy_inputfile=$1
trained_model=$2

#check input
if [ $# -lt 2 ]
then
	echo "add input (kmodes_rdy_inputfile) (trained_model.pkl)"
	echo	
	echo "note: do not have at dots '.' in inputfile path, as it may ruin output writing!"
fi


