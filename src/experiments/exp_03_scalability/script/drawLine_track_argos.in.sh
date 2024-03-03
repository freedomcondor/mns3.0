experiment_type=$1

if [[ $experiment_type == "cube_27" ]]; then
	echo "Experiment type specified: cube_27"
elif [[ $experiment_type == "cube_64" ]]; then
	echo "Experiment type specified: cube_64"
elif [[ $experiment_type == "cube_125" ]]; then
	echo "Experiment type specified: cube_125"
else
	echo "invalid parameters, please specify cube_27, cube_64 or cube_125"
	exit
fi

if [[ $experiment_type == "cube_27" ]]; then
	python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
		-i @CMAKE_MNS_DATA_PATH@/exp_03_scalability/cube_27/run_data/run1/logs \
		-t \
		-k "260, 480, 869" \
		-e 900 \
		-q 900
fi

if [[ $experiment_type == "cube_64" ]]; then
	python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
		-i @CMAKE_MNS_DATA_PATH@/exp_03_scalability/cube_64/run_data/run1/logs \
		-t \
		-k "530, 965, 1730" \
		-e 1750 \
		-q 1750 \
		-m 32
fi

if [[ $experiment_type == "cube_125" ]]; then
	python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
		-i @CMAKE_MNS_DATA_PATH@/exp_03_scalability/cube_125/run_data/run1/logs \
		-t \
		-k "790, 1230, 2300" \
		-e 2400 \
		-q 2400 \
		-m 32
fi
