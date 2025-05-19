#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/librun_threads.sh

# read experiment type
#-----------------------------------------------------
experiment_type=$1

experiment_type_list=(\
	"joystick_record_1.dat" \
	"joystick_record_2.dat" \
	"joystick_record_3.dat" \
	"joystick_record_4.dat" \
	"joystick_record_5.dat" \
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
DATADIR=@CMAKE_MNS_DATA_PATH@/exp_24_builderbot_scenario_4_large_simulation/$experiment_type/run_data
CODEDIR=$DATADIR/../code
TMPDIR=@CMAKE_BINARY_DIR@/eva_threads

# start run number, run per thread, total threads
run_threads 1 1 5\
	"lua @CMAKE_CURRENT_BINARY_DIR@/evaluator.lua" \
	$DATADIR \
	$TMPDIR \
	"----" \
	true