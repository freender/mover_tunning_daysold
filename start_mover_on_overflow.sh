#!/bin/bash
## Script runs mover if < 100 GB available on cache
## AUTHOR: Freender
## https://github.com/freender/mover_tunning_daysold/blob/main/start_mover_on_overflow.sh

# Retention Variables
target_space="107374182400" # Minimum free space after which mover runs

# Share variables:
share_path='/mnt/cache/media' #Path to you share


# Functions
# This function calculates current free space on share
get_free_space() {
  free_space=`df $share_path | awk 'NR>1{print $4*1000}'`
}


# Main Script

get_free_space # Calculate free space on our share

# Exit if more then 100 GB available
if [ $free_space -gt $target_space ]
then    
  echo "Enough space available, data mover is not required"
  #echo "Target Space=" $(($target_space / 1000000000)) "GB. Free space=" $(($free_space / 1000000000)) "GB"
  exit 1
fi 

# Otherwise run mover
echo "Not enough space available"
echo "Target Space=" $(($target_space / 1000000000)) "GB. Free space=" $(($free_space / 1000000000)) "GB"
/usr/local/sbin/mover start #&> /dev/null
