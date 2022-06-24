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

echo "Stopping data streamer container"  
cd datastreamer 
./stop.sh
cd ../
divider

echo "Stopping collectors" 
cd collector
./stop.sh
cd ../
divider

echo "Stopping stream testing engine"
cd engine
./stop.sh -e ${ENGINE_FOLDER}
cd ../
divider

