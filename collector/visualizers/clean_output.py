"""A simple python script template.
"""
from pathlib import Path
import pandas as pd 
import glob
import sys
import argparse
from typing import Pattern, Tuple
import re
from multiprocessing import Pool

def extract_latency(line:str, pattern:Pattern):
    """extract_latency.
    Cleans the given line to extract latency measurement. 
    The latency is calculated using the latest value of 
    current_timestamp in the output record, following the advice 
    of Karimov et. al. 

    The line is formatted as follows: 
    received_timestamp_ns [\\t] output_record


    *note* the received_timestamp_ns is in ns whereas 
    the current_timestamp values in the output record are in 
    ms

    :param line: the latency logged line to be parsed
    :type line: str
    :param pattern: the pattern to extract current_timestamp
    :type pattern: Pattern
    """

    matches = [int(x) for x in re.findall(pattern, line)]
    matches.sort(reverse=True)
    received_timestamp_ms = round(int(line.split("\t")[0])/1e6)


    return str(received_timestamp_ms - matches[0])

def extract_latency_file(pair:Tuple[Path, Pattern]): 

    (input_f, pattern) = pair
    output = input_f.parent.absolute().joinpath("cleaned_latency.csv").open("w")
    output.write("latency (ms), time\n")

    print("Starting to process: ",input_f )
    with open(input_f, "r") as f: 
        i = 0 
        time = 0 
        for line in f: 
            if i < 5 and "sparql-generate" in input_f.parts: 
                i+= 1 
                continue
            if len(line) > 10: 
                line = line.replace("%5B", "")
                line = line.replace("%5D", "") 
                latency = extract_latency(line, pattern) 
                latest_time = int(line.split()[0])
                if time < latest_time:
                    time = latest_time 
                output.write(latency+","+ str(latest_time) + "\n") 
    output.flush()
    truncate_influx_files(time, str(input_f.parent))
    print("Finished processing: ",input_f )

def search_files(root_dir:str, file_pattern: str):
    root_dir += "**/"
    files = [Path(file) for file in glob.iglob(
        root_dir + file_pattern,
        recursive=True)]
    return files

def truncate_influx_files(upper_limit:int, parent_dir:Path):
    files = search_files(parent_dir, "*cpu.csv")
    files = files + search_files(parent_dir, "*mem.csv")
    for file in files:
        output = file.with_name(file.with_suffix("").name + "-cleaned.csv") 
        df = pd.read_csv(file)
        df = df.loc[(df["time"] < upper_limit)]
        df.to_csv(output, index=False)
    pass

def summarise_influx_files(parent_dir:str): 
    files = search_files(parent_dir, "*cpu-cleaned.csv")
    for file in files: 
        output = file.parent
        df = pd.read_csv(file) 
        df["derivative"]= df["derivative"] /2 
        df["time"] = pd.DatetimeIndex(pd.to_datetime(df["time"], unit="ns"))
        df = df.set_index("time")
        df = df.resample("1s", label="right", closed="right").mean()
        df.to_csv(output.joinpath(file.name[:-4] + "-grouped.csv"))

    files = search_files(parent_dir, "*mem-cleaned.csv") 
    for file in files: 
        output = file.parent
        df = pd.read_csv(file)
        df["time"] = pd.DatetimeIndex(pd.to_datetime(df["time"], unit="ns"))
        df = df.set_index("time")
        df = df.resample("1s", label="right", closed="right").mean()
        df["value"] = df["value"]/1000000000
        df.to_csv(output.joinpath(file.name[:-4] + "-grouped.csv"))
        


    

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("directory", help="Directory containing the final_timestamped.log files for latency measurements.", type=str)

    args = parser.parse_args(arguments)
    directory = args.directory
    # Latency measurement logs cleaning
    pattern = re.compile("current_timestamp=([0-9]+)")
    multi_args = [Path(file) for file in glob.iglob(
        directory + "/**/final_timestamped.log", recursive=True)]
    multi_args = [(x, pattern) for x in multi_args]
    with Pool() as p: 
        p.map(extract_latency_file, multi_args)
    summarise_influx_files(directory)









if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
