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

echo "Checking into rmlstreamer source repo" 
if [[ ! -d "RMLStreamer" ]] 
then 
   echo "RMLStreamer repo doesn't exists"
   echo "Downloading the repo at https://github.com/RMLio/RMLStreamer.git"

   git clone https://github.com/RMLio/RMLStreamer.git 
fi

cd ./RMLStreamer
echo "Checking out correct branch v2.3.0" 
git checkout tags/v2.3.0 -b v2.3.0-branch 
cd ../
divider

echo "Data stream connections are live, starting engine"
./docker_setups.sh
divider

echo "Submitting RMLStreamer job to flink jobmanager"
echo ${CLI[@]}
./job_submitter.sh  ${CLI[@]}




