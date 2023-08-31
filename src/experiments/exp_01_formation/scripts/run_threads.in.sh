#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/librun_threads.sh

DATADIR=@CMAKE_MNS_DATA_PATH@/exp_01_formation/run_data
TMPDIR=@CMAKE_BINARY_DIR@/threads
THREADS_LOG_OUTPUT=`pwd`/threads_output.txt

experiment_length=500

check_finish() {
	# wc -l : check line numbers
	# cut -d ' ' means cut by space, -f1 means take the first cut word
	stepnumber=`wc logs/drone1.log -l | cut -d ' ' -f1`
	if [ $stepnumber = $experiment_length ]; then
		return 0
	else
		return 1
	fi
}

echo exp_01_formation start > $THREADS_LOG_OUTPUT # this is for run_single_threads

# start run number, run per thread, total threads
run_threads 1 5 2\
	"python3 @CMAKE_CURRENT_BINARY_DIR@/../simu_code/run.py -l $experiment_length -m 16" \
	$DATADIR \
	$TMPDIR \
	check_finish