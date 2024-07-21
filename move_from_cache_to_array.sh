#!/bin/bash

## Script estimates how many space would be reclaimed for specific share and adjusts daysold parameter to met free space criteria
## AUTHOR: Freender
## https://github.com/freender/mover_tunning_daysold/blob/main/move_from_cache_to_array.sh

# Define source and destination directories
SOURCE_DIR="/mnt/user0/media/"
DEST_DIR="/mnt/cache/media/"
TARGET_FREE_SPACE=$((400 * 1024 * 1024 * 1024))  # Target space in bytes

# Calculate human-readable format for TARGET_FREE_SPACE
TARGET_FREE_SPACE_HUMAN=$((TARGET_FREE_SPACE / 1024 / 1024 / 1024))  # Convert bytes to GB

# Variable to control soft stop
SOFT_STOP=false

# Variable to control test mode
TEST_MODE=false

# Function to handle soft stop
soft_stop_handler() {
    echo "Soft stop requested. Exiting gracefully..."
    SOFT_STOP=true
}

# Set up trap for SIGTERM
trap 'soft_stop_handler' SIGTERM

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Print usage
print_usage() {
    echo "Usage: $0 [-t] [-d DEST_DIR]"
    echo "  -t            Run in test mode (do not move files)"
    echo "  -d DEST_DIR   Specify destination directory (default: /mnt/cache/media/)"
}

# Parse command-line options
while getopts ":td:" opt; do
    case ${opt} in
        t )
            TEST_MODE=true
            ;;
        d )
            DEST_DIR=$OPTARG
            ;;
        \? )
            print_usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Remove trailing slash from DEST_DIR to avoid double slashes
DEST_DIR=$(echo "$DEST_DIR" | sed 's:/*$::')

echo "Starting script..."
echo "Checking files in the source directory..."

# Iterate over each file in the source directory
find "$SOURCE_DIR" -type f | while IFS= read -r FILE; do
    # Check for soft stop
    if [ "$SOFT_STOP" = true ]; then
        echo "Operation interrupted by soft stop."
        exit 1
    fi

    # Get the size of the file
    FILE_SIZE=$(stat -c%s "$FILE")
    
    # Get the free space available in the destination directory
    FREE_SPACE=$(df "$DEST_DIR" | awk 'NR==2 {print $4 * 1024}')
    
    # Calculate free space after moving the file
    FREE_SPACE_AFTER_MOVE=$((FREE_SPACE - FILE_SIZE))
    
    # Convert free space to human-readable format for printing
    FREE_SPACE_HUMAN=$(df -h "$DEST_DIR" | awk 'NR==2 {print $4}')

    # Convert free space after move to gigabytes for printing
    FREE_SPACE_AFTER_MOVE_HUMAN=$((FREE_SPACE_AFTER_MOVE / 1024 / 1024 / 1024))

    # Check if there will be at least the target free space after the move
    if [ $FREE_SPACE_AFTER_MOVE -ge $TARGET_FREE_SPACE ]; then
        # Remove the leading slash from the relative path
        RELATIVE_PATH="${FILE#$SOURCE_DIR}"
        DEST_SUBDIR="$DEST_DIR/$(dirname "$RELATIVE_PATH")"
        
        if [ "$TEST_MODE" = true ]; then
            echo "TEST MODE: Would move file: $FILE"
            echo "TEST MODE: Would create directory: $DEST_SUBDIR"
            echo "TEST MODE: Free space after move: ${FREE_SPACE_AFTER_MOVE_HUMAN} GB"
            echo "TEST MODE: Required free space: ${TARGET_FREE_SPACE_HUMAN} GB"
        else
            echo "Moving file: $FILE"
            
            # Create the corresponding subdirectory in the destination directory
            mkdir -p "$DEST_SUBDIR"
            
            # Move the file to the destination directory, preserving the subdirectory structure
            mv "$FILE" "$DEST_SUBDIR"
            
            # Update free space after moving the file
            FREE_SPACE=$(df "$DEST_DIR" | awk 'NR==2 {print $4 * 1024}')
            FREE_SPACE_HUMAN=$(df -h "$DEST_DIR" | awk 'NR==2 {print $4}')
            
            echo "Moved $(basename "$FILE") to $DEST_SUBDIR"
            echo "Free space after move: $FREE_SPACE_HUMAN"
            echo "Required free space after move: ${TARGET_FREE_SPACE_HUMAN} GB"
        fi
    else
        echo "Not enough free space to move file: $FILE"
        break
    fi
done

echo "Script finished."
