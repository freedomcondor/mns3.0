experiment_type=$1

if [[ $experiment_type == "left" ]]; then
	echo "Experiment type specified: left"
elif [[ $experiment_type == "right" ]]; then
	echo "Experiment type specified: right"
else
	echo "invalid parameters, please specify left or right"
	exit
fi

if [[ $experiment_type == "left" ]]; then
	python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
		-i @CMAKE_MNS_DATA_PATH@/exp_02_race_track/left/run_data/run1/logs \
		-t \
		-k "300, 750, 1096, 1781" \
		-e 1800 \
		-q 1800
fi

if [[ $experiment_type == "right" ]]; then
	python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
		-i @CMAKE_MNS_DATA_PATH@/exp_02_race_track/right/run_data/run1/logs \
		-t \
		-k "300, 750, 986, 1272, 2000" \
		-e 2001 \
		-q 2001
fi
