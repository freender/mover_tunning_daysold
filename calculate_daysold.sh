#!/bin/bash
## Script estimates how many space would be reclaimed for specific share and adjusts daysold parameter met free space criteria
## AUTHOR: Freender
## https://github.com/freender/mover_tunning_daysold/blob/main/calculate_daysold.sh

# Retention Variables
target_space="500000000000" #Set how many free space should be available after mover runs. 400 GB by default

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
  to_be_reclaimed=${to_be_reclaimed:="0"}
}
# This function updates daysold in config file
update_share_config(){
  # Update config only if daysold changed 
  if [[ $initial_retention -ne $daysold ]]
    then 
      sed -i -e 's/daysold=.*/daysold="'"$daysold"'"/g' $share_config
    fi 
}

# Main Script

# Read mover-tunning variables from config
source $share_config 
initial_retention=$daysold
get_free_space
get_reclaimable_space

# Increase $daysold if enough space available
if [ $free_space -gt $target_space ]
then
    while [[ "$to_be_reclaimed" -ne 0 ]] && [[ "$daysold" -lt 365  ]] ; do 
      daysold=$((daysold+5))
      get_reclaimable_space
    done
  update_share_config
  echo "Free space more then target space. Retention period has been updated to" $daysold "days. Share:" $share_path
  exit 1
fi 

# Decrease $daysold if not enough space available
daysold="365" # this is to find an optimal value and doesn't not move to much data
get_free_space
get_reclaimable_space
while [[ $(($free_space + $to_be_reclaimed)) -lt $target_space ]] && [[ "$daysold" -gt 0  ]] ; do 
  daysold=$((daysold-5))
  get_reclaimable_space
done

update_share_config 
 
echo "Share:" $share_path "Calculated Retention=" $daysold " To be reclaimed=" $to_be_reclaimed
