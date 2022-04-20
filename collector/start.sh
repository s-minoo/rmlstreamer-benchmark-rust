#!/bin/bash
function divider() {
    local char=$1
    if [[ -z "${1+x}" ]]; then
       char="=" 
    fi
    echo "" 
    printf "${char}%.0s"  $(seq 1 63) 
    echo "" 
}

docker-compose up -d
divider
# Since we are running rsplab in local mode
# we need to make all the container communicate in the same network
# Let's add then controller and influxdb to the demo network
docker network connect demo influxsrv
divider

echo "Waiting for influxdb...."
../wait-for-it.sh localhost:8086 -t 30
echo "Influxdb online!"
echo "Waiting for grafana...."
../wait-for-it.sh localhost:3000 -t 30 
echo "Grafana online!"
divider

