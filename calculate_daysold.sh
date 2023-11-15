#!/bin/bash
start_retention="60"
target_space="400000000000"

#TO DO - Read $start_retention from /boot/config/plugins/ca.mover.tuning/shareOverrideConfig/media.cfg
initial_retention=$start_retention
free_space=`df /mnt/cache/media | awk 'NR>1{print $4*1000}'`
to_be_reclaimed=`find /mnt/cache/media ! -mtime -$start_retention -exec ls -l {} \; -depth | grep -vFf '/mnt/user/backup/mover-ignore/mover_ignore.txt' | awk '{s+=$5} END {print s}'`

  while [[  $(($free_space + $to_be_reclaimed)) -lt $target_space ]] && [[ "$to_be_reclaimed" -gt 0  ]] ; do 
		start_retention=$((start_retention-5))
		to_be_reclaimed=`find /mnt/cache/media ! -mtime -$start_retention -exec ls -l {} \; -depth | grep -vFf '/mnt/user/backup/mover-ignore/mover_ignore.txt' | awk '{s+=$5} END {print s}'`
  done

#if [[ $initial_retention -ne $start_retention ]]; then
sed -i -e 's/daysold=.*/daysold="'"$start_retention"'"/g' /boot/config/plugins/ca.mover.tuning/shareOverrideConfig/media.cfg
