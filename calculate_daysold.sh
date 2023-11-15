#!/bin/bash
## Script estimates how many space would be reclaimed for specific share and adjusts daysold parameter met free space criteria
## AUTHOR: Freender
## https://github.com/freender/mover_tunning_daysold/blob/main/calculate_daysold.sh

# Retention Variables
start_retention="60" #Set how many days you would like to store files on a share
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
    to_be_reclaimed=`find $share_path ! -mtime -$start_retention -exec ls -l {} \; -depth | grep -vFf "$ignore_file" | awk '{s+=$5} END {print s}'`
}
# This function updates daysold in config file
update_share_config(){
    sed -i -e 's/daysold=.*/daysold="'"$start_retention"'"/g' $share_config
}

# Main Script

#TO DO - Read $start_retention from /boot/config/plugins/ca.mover.tuning/shareOverrideConfig/media.cfg
#TO DO if [[ $initial_retention -ne $start_retention ]]; then update_share_config
initial_retention=$start_retention
get_free_space
get_reclaimable_space

while [[ $(($free_space + $to_be_reclaimed)) -lt $target_space ]] && [[ "$to_be_reclaimed" -gt 0  ]] ; do 
  start_retention=$((start_retention-5))
  get_reclaimable_space
done

update_share_config

echo "Share:" $share_path "Calculated Retention=" $start_retention " Estimated Free Space=" $to_be_reclaimed
