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
    echo "Usage :  $0 -m queryFile -o outputPath [options] [--]

    Required: 
    -m|query-file       Location of query file on the local machine 
    -o|output-path      Location of the output file/folder in the container

    Options:
    -h|help             Display this message
    -v|version          Display script version"

}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvcm:o:" opt
do
    case $opt in
        m|mapping-file ) 
            MAPPING_FILE_PATH=$OPTARG ;; 
        o|output-path ) 
            OUTPUT_PATH=$OPTARG ;; 

        c|compile ) 
            COMPLE_FLAG=1 ;; 

        h|help     )  usage; exit 0   ;;

        v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;

        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;

        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;

        * )  echo -e "\n  Option does not exist : $OPTARG\n"
              usage; exit 1   ;;

    esac    # --- end of case ---
done
shift $(($OPTIND-1))

${MAPPING_FILE_PATH:? Missing mapping file -m}
${OUTPUT_PATH:? Missing output path -o}


echo "Query file is ${MAPPING_FILE_PATH}"
echo "Output data path inside the container is ${OUTPUT_PATH}"

divider


BASE_DATA_PATH="/mnt/data/"
BASE_OUTPUT_PATH="/mnt/tspfs-in/"
MAPPING_FILE_CONTAINER_PATH="${BASE_DATA_PATH}${MAPPING_FILE_PATH##*/}" 
OUTPUT_PATH="${BASE_OUTPUT_PATH}${OUTPUT_PATH}"

JM_CONTAINER=$(docker ps --filter name=sparqlgen --format={{.ID}})

echo "Copying required files into docker containers..." 
docker cp $MAPPING_FILE_PATH "${JM_CONTAINER}:${BASE_DATA_PATH}"
docker cp ./sparql-generate-2.0.9.jar "${JM_CONTAINER}":/sparql.jar
echo "Done"
echo $MAPPING_FILE_CONTAINER_PATH

divider
docker exec -t -i -d "${JM_CONTAINER}" java -jar /sparql.jar -q ${MAPPING_FILE_CONTAINER_PATH} -o ${OUTPUT_PATH} -s -l ERROR   

