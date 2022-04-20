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

echo "Starting up docker for sparql-generate..."
docker-compose up -d 

divider

echo "Starting sparql-generate..."
echo ${CLI[@]}
./job_submitter.sh  ${CLI[@]}




