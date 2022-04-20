#!/usr/bin/env bash


OUTPUT_PATH="/var/lib/influxdb/"
DATABASE="engines"
CPU_CORES=4
CONTAINER_NAME=$1

CPU_QUERY="select DERIVATIVE(value, 1s) / 1000000000 / ${CPU_CORES} from cpu_usage_total where container_name='${CONTAINER_NAME}' "
MEM_QUERY="select * from memory_working_set where container_name='${CONTAINER_NAME}'" 
RX_QUERY="select * from rx_bytes where container_name='${CONTAINER_NAME}'" 

influx --database $DATABASE  -execute "$CPU_QUERY" -format csv > "${OUTPUT_PATH}${CONTAINER_NAME}-cpu.csv"  
influx --database $DATABASE  -execute "$MEM_QUERY" -format csv > "${OUTPUT_PATH}${CONTAINER_NAME}-mem.csv"  

influx --database $DATABASE  -execute "$RX_QUERY" -format csv > "${OUTPUT_PATH}${CONTAINER_NAME}-rx.csv"  


