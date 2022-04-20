#/usr/bin/env bash

function divider() {
    local char=$1
    if [[ -z "${1+x}" ]]; then
       char="=" 
    fi
    echo "" 
    printf "${char}%.0s"  $(seq 1 63) 
    echo "" 
}

CLI=("$@")
divider
echo  "Waiting for data streamer's connection at: ${HOSTNAME}:${PORT}"
./wait-for-it.sh localhost:9000 -t 30 
./wait-for-it.sh localhost:9001 -t 30 
divider

echo "Checking out correct branch" 
cd ./rmlstreamer-source
#git checkout  feature/window_joins
cd ../
divider

echo "Data stream connections are live, starting engine"
./docker_setups.sh
divider

echo "Submitting RMLStreamer job to flink jobmanager"
echo ${CLI[@]}
./job_submitter.sh  ${CLI[@]}




