#!/bin/bash

path=/tmp
mkdir -p $path

if [ "$1" -eq "1" ]; then
    nvidia-smi --format=csv,noheader,nounits --query-gpu=index,uuid,name,memory.free,pstate,utilization.gpu,utilization.memory,temperature.gpu,timestamp -l 20 > $path/gpus.csv
fi

if [ "$1" -eq "2" ]; then
    nvidia-smi --format=csv,noheader,nounits --query-compute-apps=timestamp,gpu_uuid,used_gpu_memory,process_name,pid -l 20 > $path/processes.csv
fi

if [ "$1" -eq "3" ]; then
    while true; do
        df -l | grep " /local$" > $path/${HOST}_status.csv
        free -m | grep "Mem" >> $path/${HOST}_status.csv
        #top -b -n 1 | grep %Cpu >> $path/${HOST}_status.csv
        nproc --all >> $path/${HOST}_status.csv
        uptime >> $path/${HOST}_status.csv
        cp /tmp/local-usage.txt $path/${HOST}_local.txt

        python REPO_PATH/gpu-monitor/scripts/gpu-processes.py $path/processes.csv > $path/${HOST}_users.csv
        echo $(uptime | grep -o -P ': \K[0-9]*[,]?[0-9]*')\;$(nproc) > $path/${HOST}_cpus.csv
        tail -n 20 $path/gpus.csv > $path/${HOST}_gpus.csv
        tail -n 40 $path/processes.csv > $path/${HOST}_processes.csv
        timeout 10 scp $path/${HOST}_* $2REPO_PATH/gpu-monitor/data
        sleep 10
    done
fi
