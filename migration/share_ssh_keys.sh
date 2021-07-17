#!/bin/bash

MY_PATH="`dirname \"$0\"`"                        # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

#define style and color for printing logs
BOLD=$(tput bold);
NORMAL=$(tput sgr0);
GREEN='\033[0;92m';
RED='\033[0;91m';
NC='\033[0m'

compute_nodes=()

input_computes=$1

for compute in $input_computes
do
  compute_ip="$(getent hosts $compute | awk 'FNR==1{print $1}')"
  if [[ ${#compute_ip} -eq 0 ]]
  then
    echo "I could not resolve $compute"
    exit 1
  fi
  echo "compute <$compute> <$compute_ip> added to the list."
  compute_nodes+=($compute_ip)
done


for i in "${!compute_nodes[@]}"
do
  for j in $(seq $(( $i + 1 )) $(( ${#compute_nodes[@]} - 1 )) )
  do
    echo "swapping ${compute_nodes[i]} and ${compute_nodes[j]}"
  done
done




