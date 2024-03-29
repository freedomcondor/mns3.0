#!/bin/bash
source @CMAKE_SOURCE_DIR@/scripts/librun_threads.sh

# read experiment type
#-----------------------------------------------------
experiment_type=$1

declare -A index
index=(\
#                 exp length    argos threads    run per thread   threads
	[polyhedron_12]='500              16                 10              2'      \
	[polyhedron_20]='500              24                 10              2'      \
	[cube_27]='      600              32                 10              2'      \
	[cube_64]='      1200             32                 20              1'      \
	[cube_125]='     2500             32                 20              1'      \
	[screen_64]='    1200             32                 20              1'      \
	[donut_48]='     1200             32                 10              2'      \
	[donut_64]='     1800             32                 20              1'      \
	[donut_80]='     2200             32                 20              1'      \
)

tuple_line=${index[${experiment_type}]}
if [ -z "$tuple_line" ]; then
	echo "wrong Experiment type, please choose among:"
	for node in ${!index[@]}; do
		echo "    ${node}"
	done
	exit
fi

tuple=($tuple_line)

experiment_length=${tuple[0]}
argos_multi_threads=${tuple[1]}
run_per_thread=${tuple[2]}
number_threads=${tuple[3]}

echo "----------------------------"
echo "$experiment_type chosen, "
echo "experiment_length   = $experiment_length"
echo "argos_multi_threads = $argos_multi_threads"
echo "run_per_thread      = $run_per_thread"
echo "number_threads      = $number_threads"
echo "----------------------------"

#-----------------------------------------------------
# prepare to run threads
DATADIR=@CMAKE_MNS_DATA_PATH@/exp_01_formation/$experiment_type/run_data
CODEDIR=$DATADIR/../code
TMPDIR=@CMAKE_BINARY_DIR@/threads
#THREADS_LOG_OUTPUT=`pwd`/threads_output.txt

#echo exp_01_formation start > $THREADS_LOG_OUTPUT # this is for run_single_threads to reset $THREADS_LOG_OUTPUT

# start run number, run per thread, total threads
run_threads 1 $run_per_thread $number_threads\
	"python3 @CMAKE_CURRENT_BINARY_DIR@/../simu_code/run.py -t $experiment_type -l $experiment_length -m $argos_multi_threads" \
	$DATADIR \
	$TMPDIR \
	"check_finish_by_log_length $experiment_length"

cp -r @CMAKE_CURRENT_BINARY_DIR@/../simu_code $CODEDIR