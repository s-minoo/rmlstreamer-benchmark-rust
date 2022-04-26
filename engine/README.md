# SUT component

The SUT component is responsible for executing the engine to be evaluated 
in a docker container. cAdvisor is also started, using the `docker-compose.yml` in this folder on the same machine as SUT engine, to 
monitor the resource usage of the engine's docker container. 

In order to visualize the metrics, automatic dashboards for **Grafana** are
also created by the `create-dashboards.sh` script.
Check the [monitoring unit component](../collector/README.md) for more 
information about the underlying metrics collection using **InfluxDB**, and 
**Grafana**. 

The scripts in this component are adapted from the 
[RSPLab](https://github.com/streamreasoning/rsplab).



# Running 
The following command runs the specified engine with the given CLI args.  
`./start.sh -e [engine_folder] -- [CLI args]`

The CLI args are dependent upon the underlying engines to be evaluated.  


# Dockerfile

In order to create engine-specific docker container easier, we provide 
template **Dockerfile** which could be used to create your own 
engine container for evaluation.


# Job-submitter 

This is the script which is responsible for starting the mapping process 
once the engine container is initialized. Significant changes to this 
script might be needed depending on how complex it is to start the 
underlying engine.


