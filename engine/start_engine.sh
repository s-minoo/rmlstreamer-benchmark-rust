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

__ScriptVersion="0.0.1"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
    echo "Usage :  $0 -e engine_folder [options] [-- CLI commands]

    Required: 
    -e|engine           Location of mapping file on the local machine 

    Options:
    -h|help             Display this message
    -v|version          Display script version
    -- COMMAND ARGS     Command args to pass to the underlying engine start script
    "

}    # ----------  end of function usage  ----------

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

divider
${ENGINE_FOLDER:?Missing engine folder -e}
echo "Extra commands: "
echo ${CLI[@]}
divider

echo "Starting engines..."
CURRENT_DIR=$((pwd))
cd ${ENGINE_FOLDER}
./start.sh  ${CLI[@]}
cd ../
divider 


echo "Starting cadvisor" 
docker-compose up -d 



echo "Creating dashboards"
./wait-for-it.sh localhost:8080
./create-dashboards.sh



