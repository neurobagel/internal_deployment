#!/bin/bash

# USAGE: ./symlink_neurobagel_results_on_bic.sh <PATH TO NEUROBAGEL QUERY RESULTS TSV> <DESTINATION DIRECTORY FOR SYMLINKS>

# USAGE EXAMPLE:  ./symlink_neurobagel_results_on_bic.sh neurobagel_results.tsv /home/new_neurobagel_cohort

RESULTS_TSV=$1
TARGET_DIR=$2

SESSION_PATH_COL="SessionFilePath"
SESSION_PATH_COL_IDX=9

# Extract session path column and remove i) the column header, ii) any empty lines, iii) any "protected" lines, and iv) duplicates (just in case)
session_paths=$(cut -d $'\t' -f $SESSION_PATH_COL_IDX $RESULTS_TSV | grep -v "${SESSION_PATH_COL}" | grep -v "^$" | grep -v "protected" | sort | uniq)

for path in $session_paths; do
    if [ ! -d "$path" ]; then
        echo "Directory does not exist or is not readable: $path"
        continue
    else
        if basename "$path" | grep -q "ses-"; then
            # Dataset root should be found 4 levels up from the last directory 
            # This assumes that the dataset is nipoppified, i.e., has a top-level 'bids' directory
            dataset_root_level=4
        elif basename $path | grep -q "sub-"; then
            # Dataset root should be found 3 levels up from the last directory
            # This assumes that the dataset is nipoppified, i.e., has a top-level 'bids' directory
            dataset_root_level=3
        else
            echo "Cannot determine dataset root level for: $path"
            continue
        fi
        # Fetch the session path starting from the dataset root only
        dataset_ses_path=$(echo $path | rev | cut -d "/" -f 1-${dataset_root_level} | rev)
    
        mkdir -p "${TARGET_DIR}/$(dirname $dataset_ses_path)"
        # create symlink from created location to target
        ln -s $path "${TARGET_DIR}/${dataset_ses_path}"

        echo "Symlink created at: $(realpath --no-symlinks ${TARGET_DIR}/${dataset_ses_path})"

        dataset_root=$(echo "$dataset_ses_path" | cut -d "/" -f 1)
        if [ ! -e "${TARGET_DIR}/${dataset_root}/README.md" ]; then
            cat <<EOF > "${TARGET_DIR}/${dataset_root}/README.md"
This directory was automatically generated and contains symlinks to a subset of dataset subjects/sessions matching a Neurobagel query, who have BIDS data available on the BIC.
            
IMPORTANT: This directory imitates the structure of the original BIDS dataset, but *is not actually a valid BIDS dataset itself*.
The bids/ subdirectory can be passed as input to processing pipelines by skipping the BIDS validation step.
EOF
        fi
    fi
done
