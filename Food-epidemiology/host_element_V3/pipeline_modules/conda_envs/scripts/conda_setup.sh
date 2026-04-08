#!/bin/bash

#setup script for the BLCA_analysis conda environment
#creates the env, symlinks the BLCA command, and sets BLCA_CONFIG on activate
#run once: bash conda_setup.sh

#written by Jon Slotved (JOSS@dksund.dk)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_YML="$PROJECT_DIR/pipeline_modules/conda_envs/BLCA_analysis.yml"
BLCA_SCRIPT="$PROJECT_DIR/pipeline_modules/conda_envs/scripts/BLCA"
CONFIG_FILE="$PROJECT_DIR/config/config.env"
/pipeline_modules/conda_envs/scripts/
# echo "Script dir:####################################"
# echo "${SCRIPT_DIR}"
# echo
# echo "proj dir:####################################"
# echo "${PROJECT_DIR}"
# echo 
# echo "executable yml env:###########################"
# echo "${ENV_YML}"
# echo
# echo "BLCA script:############################"
# echo "${BLCA_SCRIPT}"

if [ ! -f "$ENV_YML" ]; then
    echo "ERROR: env yml not found: $ENV_YML"
    exit 1
fi

#create conda env
echo "creating BLCA_analysis conda environment."
#conda env create -f "$ENV_YML"

#get conda env path
CONDA_PREFIX=$(conda info --envs | grep "BLCA_analysis" | awk '{print $NF}')
echo "$CONDA_PREFIX"
exit 1


if [ -z "$CONDA_PREFIX" ]; then
    echo "ERROR: could not find BLCA_analysis env path"
    exit 1
fi

#symlink BLCA into env bin
chmod +x "$BLCA_SCRIPT"
ln -sf "$BLCA_SCRIPT" "$CONDA_PREFIX/bin/BLCA"

#set BLCA_CONFIG on conda activate
mkdir -p "$CONDA_PREFIX/etc/conda/activate.d"
echo "export BLCA_CONFIG=\"$CONFIG_FILE\"" > "$CONDA_PREFIX/etc/conda/activate.d/blca_env_vars.sh"

#unset on deactivate
mkdir -p "$CONDA_PREFIX/etc/conda/deactivate.d"
echo "unset BLCA_CONFIG" > "$CONDA_PREFIX/etc/conda/deactivate.d/blca_env_vars.sh"

echo
echo "Setup complete!"
echo "Usage:"
echo "  conda activate BLCA_analysis"
echo "  BLCA <assembly_folder> <host_tsv> [output_directory] [partition]"
