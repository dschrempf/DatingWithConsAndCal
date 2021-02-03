#!/bin/bash
# RevBayes starter
#
# Usage:
# 1. place this executable where the input files are
# 2. make it executable with chmod +x script_name.sh
# 3. execute with: nohup ./script_name.sh &
#
# Logs:
# The output will be saved to balancedRuns.jobout
# If some error happens before srun it will be outputted to $HOME/nohup.out
#
# number of tasks for a file (in same order as files)
TASKS=("FOURSHERE")
# comma separated list of partitions
PARTITIONS="med"
# threads per instance of program needed
THREADS="1"
# expected runtime
TIME="0"
# jobname prefix
JOBNAME="balancedRuns"
#
MEMORY="1500"
#in Mb per CPU
# program to launch
PROGRAMS=("TOREPLACEWITH28JOBS")

#### Dating the tree without constraints, with balanced calibrations:
for id in "${!PROGRAMS[@]}"; do
srun --mem-per-cpu=${MEMORY} -n ${TASKS[$id]} -c $THREADS -o ${JOBNAME}_%j.jobout -p $PARTITIONS -J ${JOBNAME}_0 --time $TIME -- ${PROGRAMS[$id]} > ${JOBNAME}_$id_rb.out &
sleep 1
done


# wait for sruns to finish
