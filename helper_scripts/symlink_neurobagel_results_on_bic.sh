#!/bin/bash

# USAGE: ./symlink_neurobagel_results_on_bic.sh <PATH TO NEUROBAGEL QUERY RESULTS TSV> <DESTINATION DIRECTORY FOR SYMLINKS>

# USAGE EXAMPLE:  ./symlink_neurobagel_results_on_bic.sh neurobagel-query-results.tsv /home/new_neurobagel_cohort

RESULTS_TSV=$1
TARGET_DIR=$2

SESSION_PATH_COL="ImagingSessionPath"
SESSION_PATH_COL_IDX=6

LOG_FILE="/data/pd/neurobagel/scripts/symlink_neurobagel_results_on_bic.log"
LOCK_FILE="/data/pd/neurobagel/scripts/symlink_neurobagel_results_on_bic.lock"

# Extract session path column and remove i) the column header, ii) any empty lines, iii) any "protected" lines, and iv) duplicates (just in case)
session_paths=$(cut -d $'\t' -f $SESSION_PATH_COL_IDX $RESULTS_TSV | grep -v "${SESSION_PATH_COL}" | grep -v "^$" | grep -v "protected" | sort | uniq)

for path in $session_paths; do
    if [ ! -d "$path" ]; then
        echo "Source directory does not exist or is not readable: $path"
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
            
IMPORTANT: This directory imitates the structure of the original BIDS dataset, but is NOT actually a valid BIDS dataset itself!
The bids/ subdirectory can be passed as input to processing pipelines by skipping the BIDS validation step.
EOF
        fi
    fi
done

# If log file exists, write datetime and user ID of run to log file
# This keeps a basic record of how many times and by how many unique users the script was run
if [ -f $LOG_FILE ]; then
    # Check if lock file exists (it should be pre-created, because not all users will have write permissions to the shared directory itself)
    if [ -f $LOCK_FILE ]; then
        # Open lockfile and associate it with arbitrary file descriptor 200 (specific to the context of this process/script)
        exec 200>$LOCK_FILE
        # Try to acquire the lock associated with the lockfile. 
        # If the lockfile is already "locked", flock first waits until the lock is released
        flock 200
    fi
    # Log that script was run (only date and user ID) for debugging and to get a sense of script usage
    echo -e "Date run: $(date)\tUser ID: $(id -u)">> $LOG_FILE
fi
