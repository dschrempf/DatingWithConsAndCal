#!/bin/bash
# RevBayes starter
#
# Usage:
# 1. place this executable where the input files are
# 2. make it executable with chmod +x script_name.sh
# 3. execute with: nohup ./script_name.sh &
#
# Logs:
# The output will be saved to Rep_1.jobout
# If some error happens before srun it will be outputted to $HOME/nohup.out
#
# number of tasks for a file (in same order as files)
TASKS=("4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" "4" )
# comma separated list of partitions
PARTITIONS="med"
# threads per instance of program needed
THREADS="1"
# expected runtime
TIME="0"
# jobname prefix
JOBNAME="Rep_1"
#
MEMORY="1500"
#in Mb per CPU
# program to launch
PROGRAMS=( "bash RandomConstraintOrders/Rep_1/balanced_10.sh" "bash RandomConstraintOrders/Rep_1/balanced_11.sh" "bash RandomConstraintOrders/Rep_1/balanced_12.sh" "bash RandomConstraintOrders/Rep_1/balanced_13.sh" "bash RandomConstraintOrders/Rep_1/balanced_14.sh"  "bash RandomConstraintOrders/Rep_1/unbalanced_1.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_2.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_3.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_4.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_5.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_6.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_7.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_8.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_9.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_10.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_11.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_12.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_13.sh" "bash RandomConstraintOrders/Rep_1/unbalanced_14.sh")

#### Dating the tree without constraints, with balanced calibrations:
for id in "${!PROGRAMS[@]}"; do
srun --mem-per-cpu=${MEMORY} -n ${TASKS[$id]} -c $THREADS -o ${JOBNAME}_%j.jobout -p $PARTITIONS -J ${JOBNAME}_0 --time $TIME -- ${PROGRAMS[$id]} > ${JOBNAME}_$id_rb.out &
sleep 1
done


# wait for sruns to finish
