#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/librun_threads.sh

# read experiment type
#-----------------------------------------------------
experiment_type=$1

experiment_type_list=(\
	"cube_27"       \
	"cube_64"       \
	"cube_125"       \
)

#if [ ! -z "$experiment_type" ] && [[ "${experiment_type_list[@]}" =~ "$experiment_type" ]]; then
if [[ $(echo ${experiment_type_list[@]} | fgrep -w $experiment_type) ]]; then
	echo "$experiment_type" chosen
else
	echo "wrong Experiment type, please choose among:"
	for node in ${experiment_type_list[@]}; do
		echo "    ${node}"
	done
	exit
fi

# prepare to run threads
#-----------------------------------------------------
DATADIR=@CMAKE_MNS_DATA_PATH@/exp_03_scalability/$experiment_type/run_data
CODEDIR=$DATADIR/../code
TMPDIR=@CMAKE_BINARY_DIR@/eva_threads
#THREADS_LOG_OUTPUT=`pwd`/threads_evaluator_output.txt

#echo exp_01_formation start > $THREADS_LOG_OUTPUT # this is for run_single_threads to reset $THREADS_LOG_OUTPUT

# start run number, run per thread, total threads
run_threads 1 1 20\
	"lua @CMAKE_CURRENT_BINARY_DIR@/evaluator.lua" \
	$DATADIR \
	$TMPDIR \
	"----" \
	true