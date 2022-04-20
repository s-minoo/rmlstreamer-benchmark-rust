import argparse
import glob
import os
from pathlib import Path
import functools 
import pandas as pd
import numpy as np 
import sys

import matplotlib.pyplot as plt
from matplotlib.pyplot import Axes


plt.style.context("seaborn-muted")

def box_plot(df: pd.DataFrame, output: str):
    """box_plot.

    :param df: the dataframe containing the csv table of measurements
    :type df: pd.DataFrame
    :param output: output file name of the visualization image 
    :type output: str
    """

    ax = plt.subplot(111)
    bplot2 = ax.boxplot(df, vert=True, showfliers=False)

    ax.set_xticks([])
    ax.set_ylabel("Latency (ms)")
    for key in ["whiskers", "medians", "caps"]:
        for line in bplot2[key]:
            (_, y), (xr, _) = line.get_xydata()
            if key == "whiskers":
                xr = xr + 0.04
            xr = xr + 0.05
            ax.text(xr, y, "%3.f" % y,
                    verticalalignment="center",
                    fontsize=12)

    plt.savefig(output)
    plt.close()
    pass

def search_files(root_dir:str, file_pattern: str):
    root_dir += "**/"
    files = [Path(file) for file in glob.iglob(
        root_dir + file_pattern,
        recursive=True)]
    return files


def visualize_latency(root_dir: str):
    latency_files = search_files(root_dir, "cleaned_latency.csv")

    for file in latency_files:
        df = pd.read_csv(file)
        box_plot(df, file.parent.absolute()/'latency_boxplot.png')

def line_plot(df: pd.DataFrame, output:Path, **kwargs):

    
    df.plot.line(**kwargs).get_figure().savefig(output)

    
    pass



def get_files(root_dir, engine, pattern):
    mem_files = search_files(root_dir, engine + pattern + "*mem-cleaned-grouped.csv")
    cpu_files = search_files(root_dir, engine + pattern +  "*cpu-cleaned-grouped.csv")
    latency_files = search_files(root_dir, engine + "/*cleaned_latency.csv")
    return latency_files, cpu_files, mem_files

def periodic_df(root_dir: str, engine:str, pattern:str): 
    lat_files, cpu_files, mem_files = get_files(root_dir, engine, pattern) 
    if len(lat_files) == 0: 
        return
    throughput_files = search_files(root_dir, engine + "/**/*.data.log.csv")
    
    thr_dfs = [pd.read_csv(x) for x in throughput_files]
    thr_df = None
    if len(thr_dfs) > 1: 
        thr_df = thr_dfs[0] + thr_dfs[1]
        thr_df["throughput (msg/s)"] = thr_df["throughput (msg/s)"].apply(lambda x: x/2 if x > 169 and x <400 else x)
    else: 
        thr_df = thr_dfs[0]

    val_range = 60

    lat_df = pd.read_csv(lat_files[0])
    lat_df.rename(columns= {" time": "time", "latency (ms)": engine +"-50"}, inplace=True)
    lat_df["time"] = pd.DatetimeIndex(pd.to_datetime(lat_df["time"], unit="ns"))
    lat_df = lat_df.set_index("time") 
    new_lat_df=lat_df.resample("1s", label="right", closed="right").apply(
        lambda x: np.percentile(x, q=50)
    )

    thr_df = thr_df.tail(val_range).reset_index(drop=True).rename(columns={"throughput (msg/s)": engine+"-throughput"})
    lat_df = new_lat_df.tail(val_range).reset_index(drop=True)/1000
    cpu_df = pd.read_csv(cpu_files[0]).tail(val_range).drop(labels=["time"], axis =1).reset_index(drop=True).rename(columns={"derivative": engine+ "-cpu"})
    mem_df = pd.read_csv(mem_files[0]).tail(val_range).drop(labels=["time"], axis =1).reset_index(drop=True).rename(columns={"value": engine + "-mem"})

    return [thr_df, lat_df, cpu_df, mem_df ]

def periodic_plot(rml_dfs, sparql_dfs, root_dir:str): 

    df_out_tups = [(pd.concat([x,y],axis=1),x.columns[0].split("-")[1])
                   for x,y in zip(rml_dfs,sparql_dfs)]
    for df, output in df_out_tups: 
        num_style = int(len(df.columns)/2)
        first_style = ["--" for _ in range(num_style)]
        second_style = ["-" for _ in range(num_style)]
        
        line_plot(df, Path(root_dir+"/periodic-"+output+".png"), style=first_style + second_style, legend=False)


def throughput_measurement_plot(root_dir:str, engine:str, pattern:str): 
    latency_files, cpu_files, mem_files = get_files(root_dir, engine, pattern)
    
    latency_percentiles = [ (int(x.parents[1].name.split("_")[-1][:-1])*340,
                            pd.read_csv(x)["latency (ms)"].quantile(q=0.5)/1000) 
                           for x in latency_files]
    cpu_avg = [ (int(x.parents[1].name.split("_")[-1][:-1])*340, 
                 pd.read_csv(x)["derivative"].mean()*100)
                 for x in cpu_files]
    mem_avg = [ (int(x.parents[1].name.split("_")[-1][:-1])*340, 
                 pd.read_csv(x)["value"].mean())
                 for x in mem_files]

    latency_percentiles.sort(key=lambda x: x[0])
    cpu_avg.sort(key=lambda x: x[0])
    mem_avg.sort(key=lambda x: x[0])
    
    lat_df = pd.DataFrame(latency_percentiles, columns=["throughput", engine+"-lat"])
    lat_df = lat_df.set_index("throughput")
    cpu_df = pd.DataFrame(cpu_avg, columns=["throughput", engine+"-cpu"])
    cpu_df = cpu_df.set_index("throughput")
    mem_df = pd.DataFrame(mem_avg, columns=["throughput", engine+"-mem"])
    mem_df = mem_df.set_index("throughput")
    
    return lat_df, cpu_df, mem_df

   
def throughput_plot(rml_dfs, sparql_dfs, root_dir:str): 
    df_out_tups = [(pd.concat([x,y],axis=1),x.columns[0].split("-")[1])
                   for x,y in zip(rml_dfs,sparql_dfs)]
    for df, output in df_out_tups: 
        num_style = int(len(df.columns)/2)
        first_style = ["--o" for _ in range(num_style)]
        second_style = ["-^" for _ in range(num_style)]
        
        line_plot(df, Path(root_dir+"/throughput-"+output+".png"), style=first_style + second_style,xlim=[0,80000], legend=False)

    


def main(arguments):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('directory', help="Input latency logged file",
                        type=str)

    args = parser.parse_args(arguments)
    visualize_latency(args.directory)
    c_dir = args.directory + "/constant/"
    rml = throughput_measurement_plot(c_dir, "rmlstreamer" , "/**/*taskmanager")
    sparql = throughput_measurement_plot(c_dir, "sparql-generate", "/**/")
    print(len(rml))
    print(len(sparql))
    throughput_plot(rml, sparql, c_dir)

    periodic_dirs = [x for x in glob.iglob(args.directory+"/periodic/*/")]
    for p_dir in periodic_dirs: 
        rml = periodic_df(p_dir, "rmlstreamer", "/**/*taskmanager")
        sparql = periodic_df(p_dir, "sparql-generate", "/**/")
        if sparql is None: 
            continue
        periodic_plot(rml, sparql, p_dir)

   #periodic_plot(args.directory+"/periodic/","sparql-generate", "/**/")
   #throughput_measurement_plot(args.directory+"/constant/", "rmlstreamer", "/**/*taskmanager*")
   #throughput_measurement_plot(args.directory+"/constant/", "sparql-generate", "/**/")
   #visualize_latency(args.directory)
    

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
