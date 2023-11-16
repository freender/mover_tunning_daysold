#!/bin/bash
## Script estimates how many space would be reclaimed for specific share and adjusts daysold parameter met free space criteria
## AUTHOR: Freender
## https://github.com/freender/mover_tunning_daysold/blob/main/calculate_daysold.sh

# Retention Variables
target_space="400000000000" #Set how many free space should be available after mover runs. 400 GB by default

# Share variables:
ignore_file='/mnt/user/backup/mover-ignore/mover_ignore.txt' #File with list of directories ignored by mover
share_path='/mnt/cache/media' #Path to you share
share_config='/boot/config/plugins/ca.mover.tuning/shareOverrideConfig/media.cfg' #Path to config with share override settings


# Functions
# This function calculates current free space on share
get_free_space() {
    free_space=`df $share_path | awk 'NR>1{print $4*1000}'`
}
# This function calculates how many space is estimated to be reclaimed
get_reclaimable_space() {
    to_be_reclaimed=`find $share_path ! -mtime -$daysold -type f -printf "%s %p\n" | grep -vFf "$ignore_file" | awk '{s+=$1} END {print s}'`
}
# This function updates daysold in config file
update_share_config(){
    sed -i -e 's/daysold=.*/daysold="'"$daysold"'"/g' $share_config
}

# Main Script

# Read mover-tunning variables from config
source $share_config 
initial_retention=$daysold
get_free_space
get_reclaimable_space

# Check if mover should be executed today
if [ $free_space -gt $target_space ]
then
  start_retention=$((start_retention+5))
  update_share_config
  echo "Mover is not required. Share:" $share_path
  exit 1
fi 

# If should - calculate new retention period
while [[ $(($free_space + $to_be_reclaimed)) -lt $target_space ]] && [[ "$to_be_reclaimed" -gt 0  ]] ; do 
  start_retention=$((start_retention-5))
  get_reclaimable_space
done

# Update config only if daysold changed 
if [[ $initial_retention -ne $daysold ]]
then update_share_config
  update_share_config 
fi 

echo "Share:" $share_path "Calculated Retention=" $daysold " Estimated Free Space=" $to_be_reclaimed
