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


function cleanup() {
    #function_body
    divider
    echo "Cleaning up..." 
    docker-compose stop 
    exit 1 
}

__ScriptVersion="0.0.1"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
    echo "Usage :  $0 [options] [--]

    Options:
    -s|stop       Stop the containers provided by docker-compose.yaml 
    -h|help       Display this message
    -v|version    Display script version"

}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvs" opt
do
  case $opt in
    s|stop     )
        divider; 
        echo "Stopping docker containers..."; 
        divider; 
        docker-compose stop; 
        exit 0;; 


    h|help     )  usage; exit 0   ;;

    v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;

    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;

    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;

    * )  echo -e "\n  Option does not exist : $OPTARG\n"
          usage; exit 1   ;;

  esac    # --- end of case ---
done
shift $(($OPTIND-1))


trap cleanup SIGHUP SIGINT SIGTERM

echo "Starting up necessary docker containers for Flink..." 
divider 

docker-compose up -d 
divider 
