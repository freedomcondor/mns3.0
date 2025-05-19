#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/librun_threads.sh

# prepare to run threads
#-----------------------------------------------------
DATADIR=@CMAKE_MNS_DATA_PATH@/exp_23_builderbot_scenario_3_large_simulation/run_data
CODEDIR=$DATADIR/../code
TMPDIR=@CMAKE_BINARY_DIR@/eva_threads
#THREADS_LOG_OUTPUT=`pwd`/threads_evaluator_output.txt

# start run number, run per thread, total threads
run_threads 1 1 20\
	"lua @CMAKE_CURRENT_BINARY_DIR@/evaluator.lua" \
	$DATADIR \
	$TMPDIR \
	"----" \
	true