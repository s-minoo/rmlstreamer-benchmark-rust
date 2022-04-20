#!/usr/bin/env bash

function divider() {
   local char=$1
    if [[ -z "${1+x}" ]]; then
       char="=" 
    fi
    echo "" 
    printf "${char}%.0s"  $(seq 1 63) 
    echo "" 
}

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -e|--engine)
      ENGINE_FOLDER="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help) usage; exit 0   ;;
    --)
    shift
    CLI=("$@")
    break;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      echo "Unknown option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
${ENGINE_FOLDER:?Missing engine folder -e}

echo "creating a common network for all containers"
docker network create eval
divider


echo "Starting influxdb and grafana "
cd collector
./start.sh
cd ../
divider 

echo "Starting data streamer" 
cd data-streamer
./start.sh
cd ../ 
divider

echo "Waiting for data streamer connection to be live" 
./wait-for-it.sh localhost:9000 -t 30 
./wait-for-it.sh localhost:9001 -t 30   

divider
echo "Starting stream testing engine"
cd engine
./start_engine.sh  -e ${ENGINE_FOLDER} -- ${CLI[@]} 
cd ../

