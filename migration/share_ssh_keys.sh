#!/bin/bash

#define style and color for printing logs
BOLD=$(tput bold);
NORMAL=$(tput sgr0);
GREEN='\033[0;92m';
RED='\033[0;91m';
NC='\033[0m'
current_pid=$$

compute_nodes=()
compute_names=()

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
  compute_names+=($compute)
done

create_directory="mkdir -p /root/.ssh"
create_file="/root/.ssh/authorized_keys"
temp="ssh-keygen -t ed25519 -N "" -C "" -f /root/.ssh/$compute"
for i in "${!compute_nodes[@]}"
do
  for j in $(seq $(( $i + 1 )) $(( ${#compute_nodes[@]} - 1 )) )
  do
    echo "swapping ${compute_nodes[i]} and ${compute_nodes[j]}"
    $( ssh  ${compute_nodes[i]} $create_directory ) && $( ssh  ${compute_nodes[j]} $create_directory ) && \
    $( ssh  ${compute_nodes[i]} $create_file ) && $( ssh  ${compute_nodes[j]} $create_file ) && \
    echo "success creating dir and file" && \
    $( ssh  ${compute_nodes[i]} "ssh-keygen -t ed25519 -N '' -C '' -f '/root/.ssh/${compute_names[i]}'" ) && $( ssh  ${compute_nodes[j]} "ssh-keygen -t ed25519 -N '' -C '' -f '/root/.ssh/${compute_names[j]}'" ) && \
    echo "success generating ssh keys" && \
    $( scp  "${compute_nodes[i]}:/root/.ssh/${compute_names[i]}.pub" "/tmp/$($current_pid)-${compute_names[i]}" ) && $( scp  "${compute_nodes[j]}:/root/.ssh/${compute_names[j]}.pub" "/tmp/$($current_pid)-${compute_names[j]}" ) && \
    echo "success getting PUB KEYs" && \
    $( scp "/tmp/$($current_pid)-${compute_names[j]}" "${compute_nodes[i]}:/tmp" ) && $( scp "/tmp/$($current_pid)-${compute_names[i]}" "${compute_nodes[j]}:/tmp" ) && \
    echo "success transmitting swapped PUB KEYs" && \
    $( ssh  ${compute_nodes[i]} "echo '/tmp/$($current_pid)-${compute_names[j]}' >> '/root/.ssh/authorized_keys'" ) && $( ssh  ${compute_nodes[j]} "echo '/tmp/$($current_pid)-${compute_names[i]}' >> '/root/.ssh/authorized_keys'" ) &&
    echo "success adding swapped PUB KEYs to respective authorized_keys" && continue

    echo "FAILURE"
  done
done
