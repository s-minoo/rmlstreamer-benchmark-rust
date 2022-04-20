#!/bin/bash


docker cp "./collect.sh" influxsrv:/

for x in `docker ps --filter label=monitor=t --format '{{.Names}}\t' | awk '{print $1}'` ; do
    echo "Collecting results for ${x}"
    docker exec influxsrv "./collect.sh" "${x}"
done


docker-compose down
