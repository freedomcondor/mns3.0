LOG_INDENT="                |"
  LOG_LINE="-----------------"

# set default dirs and output files
THREADS_LOG_OUTPUT=/dev/stdout      #absolute path   overwrite with `pwd`/threads_output.txt
KILL_THREADS=`pwd`/kill_threads.sh  # absolute path
RUN_OUTPUT=run_output.log # relative path, relative to the runX folder
EVA_OUTPUT=eva_output.log # relative path, relative to the runX folder

DATADIR=data
TMPDIR=.

check_finish_by_log_length() {
	experiment_length=$1
	# wc -l : check line numbers
	# cut -d ' ' means cut by space, -f1 means take the first cut word
	stepnumber=`wc logs/drone1.log -l | cut -d ' ' -f1`
	if [ $stepnumber = $experiment_length ]; then
		return 0
	else
		return 1
	fi
}

run() {
	CURRENTDIR=`pwd`

	# `run 2 3` means run No.2 on thread No.3 (thread No is for indents)
	# check if run2 has already finished in DATADIR, if so then skip
	#   This done by checking if run2 is in $DATADIR and not in $TMPDIR
	#   This is because in the last time the run may be interrupted in the copy process
	# create run2 folder in $TMPDIR folder, run cmd in it, and copy run2 to DATADIR
	# run cmd will be added "-r $run_number -v false" options, the output will be directed to $RUN_OUTPUT
	# 
	run_number=$1
	thread_number=$2
	cmd=$3
	DATADIR=$4
	TMPDIR=$5
	check_finish_correctly_program=$6

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	# check if datadir case exists and it is already finished in current folder
	if [ -d "$DATADIR/run$run_number" ] && [ ! -d "$TMPDIR/run$run_number" ]; then
		echo "$log_indent skip run$run_number" >> $THREADS_LOG_OUTPUT
		return
	fi

	# create a runX folder in current folder and run cmd
	echo "$log_indent run $run_number start" >> $THREADS_LOG_OUTPUT

	rm -rf $TMPDIR/run$run_number
	mkdir -p $TMPDIR/run$run_number
	cd $TMPDIR/run$run_number
	mkdir logs

	# run cmd
	repeat_flag=1
	while [ $repeat_flag -eq 1 ]; do
		$cmd -r $run_number -v false > $RUN_OUTPUT

		# consider check program is mandatory
		# if check finish if not provided
		#if [ -z "$check_finish_correctly_program" ]; then
		#	break
		#fi
		# else run check finish and set repeat_flag based on its result
		$check_finish_correctly_program
		result=$?
		if [ $result -eq 0 ]; then
			echo "$log_indent run$run_number check" >> $THREADS_LOG_OUTPUT
			repeat_flag=0
		else
			echo repeating run$run_number
			echo "$log_indent run$run_number repeated" >> $THREADS_LOG_OUTPUT
			repeat_flag=1
		fi
	done

	cd $CURRENTDIR  # cmd may fail to run
	rm -rf $DATADIR/run$run_number
	mkdir -p $DATADIR/run$run_number
	mv -f $TMPDIR/run$run_number $DATADIR

	echo "$log_indent run $run_number finish" >> $THREADS_LOG_OUTPUT
	cd $TMPDIR
	rm -rf run$run_number

	cd $CURRENTDIR
}

evaluate() {
	CURRENTDIR=`pwd`

	# go to $DATADIR/run$run_number and run cmd

	run_number=$1
	thread_number=$2
	cmd=$3
	DATADIR=$4

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	if [ ! -d $DATADIR/run$run_number ]; then
		echo "$log_indent"run$run_number "does't exist" >> $THREADS_LOG_OUTPUT
		return
	fi

	echo "$log_indent"evaluating run$run_number >> $THREADS_LOG_OUTPUT
	cd $DATADIR/run$run_number
	$cmd > $EVA_OUTPUT
	cd $CURRENTDIR
	echo "$log_indent"eva run$run_number finish >> $THREADS_LOG_OUTPUT
}

run_single_thread() {
	start=$1
	end=$2
	step=$3
	thread_number=$4
	cmd=$5
	DATADIR=$6
	TMPDIR=$7
	check_finish_correctly_program=$8
	evaluation_flag=$9

	# log indent for this thread
	log_indent=""
	for (( indent=0; indent<$thread_number; indent++ )); do log_indent="$log_indent$LOG_INDENT"; done

	echo "$log_indent thread $thread_number start" >> $THREADS_LOG_OUTPUT

	for (( i_run=$start; i_run<=$end; i_run+=$step ));
	do
		if [ -z "$evaluation_flag" ]; then
			run $i_run $thread_number "$cmd" $DATADIR $TMPDIR "$check_finish_correctly_program"
		else
			evaluate $i_run $thread_number "$cmd" $DATADIR
		fi
	done

	echo "$log_indent thread $thread_number finish" >> $THREADS_LOG_OUTPUT
}

run_threads() {
	start=$1
	runs_per_thread=$2
	threads=$3
	cmd=$4
	DATADIR=$5
	TMPDIR=$6
	check_finish_correctly_program=$7
	evaluation_flag=$8

	# create kill_threads.sh
	echo "ps -a" > $KILL_THREADS
	echo "echo ---------------" >> $KILL_THREADS
	echo "echo killing threads" >> $KILL_THREADS


	if [ -z "$evaluation_flag" ]; then
		echo "Threads start, execute in $TMPDIR," > $THREADS_LOG_OUTPUT
		echo "copy back in $DATADIR" >> $THREADS_LOG_OUTPUT
	else
		echo "evaluating_flag detected : $evaluating_flag" > $THREADS_LOG_OUTPUT
		echo "evaluating, in $DATADIR" >> $THREADS_LOG_OUTPUT
	fi

	# create temp dir
	if [ -d $TMPDIR ]; then
		echo "[warning] $TMPDIR already exists" >> $THREADS_LOG_OUTPUT
	else
		mkdir -p $TMPDIR
	fi

	screen_width=`tput cols`
	width=$(( $screen_width / 25 ))
	LOG_LINE=""
	for (( i=0; i<$width; i++)); do LOG_LINE="$LOG_LINE-"; done
	LOG_INDENT=""
	for (( i=1; i<$width; i++)); do LOG_INDENT="$LOG_INDENT "; done
	LOG_INDENT="$LOG_INDENT|"

	# line length
	log_line=""
	for (( indent=0; indent<$threads; indent++ )); do log_line="$log_line$LOG_LINE"; done

	# start log
	echo "Threads start" >> $THREADS_LOG_OUTPUT
	echo "$log_line" >> $THREADS_LOG_OUTPUT

	# start threads
	for (( i_thread=0; i_thread<$threads; i_thread++ )); 
	do 
		#let thread_start=$start+$runs_per_thread*$i_thread
		#let thread_end=$thread_start+$runs_per_thread-1
		#run_single_thread $thread_start $thread_end $i_thread "$cmd" $DATADIR $TMPDIR "$check_finish_correctly_program" $evaluation_flag &
		thread_start=$(($i_thread+$start))
		thread_end=$(($thread_start+($runs_per_thread-1)*$threads))
		thread_step=$threads
		run_single_thread $thread_start $thread_end $thread_step $i_thread "$cmd" $DATADIR $TMPDIR "$check_finish_correctly_program" $evaluation_flag &
		echo "kill $!" >> $KILL_THREADS
	done

	echo "echo killing all argos3" >> $KILL_THREADS
	echo "killall argos3" >> $KILL_THREADS
	echo "echo killing all python3" >> $KILL_THREADS
	echo "killall python3" >> $KILL_THREADS
	echo "echo killing all lua" >> $KILL_THREADS
	echo "killall lua" >> $KILL_THREADS
	echo "sleep 1" >> $KILL_THREADS
	echo "echo ---------------" >> $KILL_THREADS
	echo "ps -a" >> $KILL_THREADS

	# wait to finish
	wait
	echo "$log_line" >> $THREADS_LOG_OUTPUT
	echo "Experiment finish" >> $THREADS_LOG_OUTPUT

	# clean
	rm $KILL_THREADS
	rm -rf $TMPDIR
}