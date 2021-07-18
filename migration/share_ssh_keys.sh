#!/bin/bash

#define style and color for printing logs
BOLD=$(tput bold);
NORMAL=$(tput sgr0);
GREEN=`tput setaf 2`;
RED=`tput setaf 1`;
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
    echo "${RED}I could not resolve $compute${NORMAL}"
    exit 1
  fi
  echo "compute ${BOLD}${GREEN} <$compute> <$compute_ip>  ${NORMAL}added to the list."
  compute_nodes+=($compute_ip)
  compute_names+=($compute)
done

create_directory="mkdir -p /root/.ssh"
create_file="touch /root/.ssh/authorized_keys"

for i in "${!compute_nodes[@]}"
do
  for j in $(seq $(( $i + 1 )) $(( ${#compute_nodes[@]} - 1 )) )
  do
    echo "swapping ${GREEN} ${compute_nodes[i]} ${NORMAL} and ${GREEN} ${compute_nodes[j]} ${NORMAL}"
    $( ssh  ${compute_nodes[i]} $create_directory ) && $( ssh  ${compute_nodes[j]} $create_directory ) && \
    $( ssh  ${compute_nodes[i]} $create_file ) && $( ssh  ${compute_nodes[j]} $create_file ) && \
    echo "${BOLD} success creating dir and file ${NORMAL}" && \
#sed -e '/BBB/ s/^#*/#/' -i file 
    cmd1="sed -e '/${compute_nodes[j]}/ s/^#*/#/g' -i '/etc/hosts'" && \
    cmd2="sed -e '/${compute_nodes[i]}/ s/^#*/#/g' -i '/etc/hosts'" && \
    $(ssh "${compute_nodes[i]}" "$cmd1" >/dev/null) && $(ssh "${compute_nodes[j]}" "$cmd2" >/dev/null) && \
    echo "${BOLD} success cleaning hosts and IPs ${NORMA}L" && \
    cmd1="ssh-keygen -q -N '' -t ed25519 -f \"/root/.ssh/id_ed25519\" <<<y" && \
    cmd2="ssh-keygen -q -N '' -t ed25519 -f \"/root/.ssh/id_ed25519\" <<<y" && \
    $(ssh "${compute_nodes[i]}" "$cmd1" >/dev/null) && $(ssh "${compute_nodes[j]}" "$cmd2" >/dev/null) && \
    echo "${BOLD} success generating ssh keys ${NORMAL}" && \
    cmd1="echo '${compute_nodes[j]}   ${compute_names[j]}' >> /etc/hosts" && \
    cmd2="echo '${compute_nodes[i]}   ${compute_names[i]}' >> /etc/hosts" && \
    $(ssh "${compute_nodes[i]}" "$cmd1" >/dev/null) && $(ssh "${compute_nodes[j]}" "$cmd2" >/dev/null) && \
    echo "${BOLD} success adding hosts and IPs ${NORMAL}" && \
    `touch "/tmp/$$-${compute_names[i]}" >/dev/null` &&\
    `touch "/tmp/$$-${compute_names[j]}" >/dev/null` &&\
    $(scp "${compute_nodes[i]}:/root/.ssh/id_ed25519.pub" "/tmp/$$-${compute_names[i]}" >/dev/null) && $( scp  "${compute_nodes[j]}:/root/.ssh/id_ed25519.pub" "/tmp/$$-${compute_names[j]}" >/dev/null) && \
    echo "${BOLD} success getting PUB KEYs ${NORMAL}" && \
    $( scp "/tmp/$$-${compute_names[j]}" "${compute_nodes[i]}:/tmp" ) && $( scp "/tmp/$$-${compute_names[i]}" "${compute_nodes[j]}:/tmp" ) && \
    echo "${BOLD} success transmitting swapped PUB KEYs ${NORMAL}" && \
    $( ssh  ${compute_nodes[i]} "cat '/tmp/$$-${compute_names[j]}' >> '/root/.ssh/authorized_keys'" >/dev/null) && $( ssh  ${compute_nodes[j]} "cat '/tmp/$$-${compute_names[i]}' >> '/root/.ssh/authorized_keys'" >/dev/null) &&
    echo "${BOLD} success adding swapped PUB KEYs to respective authorized_keys ${NORMAL}" && continue

    echo "$RED FAILURE $NC"
  done
done
