experiment_type=$1

declare -A index
index=(\
#                    experiment length
	[polyhedron_12]='400   position="-45.5039,-74.718,35.2371"look_at="2.36992,-3.8366,4.10825"' \
	[polyhedron_20]='450   position="-80.1868,-28.6278,47.6129"look_at="0.106208,-6.92983,10.6358"' \
	[cube_27]='      500   position="-31.8851,-39.3,48.4403"look_at="13.8916,20.4892,-2.69511"'      \
	[cube_64]='      600   position="-31.8851,-39.3,48.4403"look_at="13.8916,20.4892,-2.69511"'      \
	[cube_125]='     810   position="-31.8851,-39.3,48.4403"look_at="13.8916,20.4892,-2.69511"'  \
	[donut_48]='     670   position="-41.0817,-59.2893,64.4446"look_at="-2.87857,3.7938,11.0955"'      \
	[donut_64]='     970   position="-41.8704,-53.1639,68.5449"look_at="-4.18923,6.36437,10.9116"'  \
	[donut_80]='     1200  position="-42.8467,-53.3419,63.9209"look_at="-3.96572,6.7569,7.6938"'  \
	[screen_64]='    810   position="-74.2383,-34.4149,33.5239"look_at="3.34592,11.1728,19.8295"'   \
	[cube_1000]='    3300  position="-85.7698,52.1927,109.786"look_at="5.08687,-14.5241,52.8338"'   \
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
camera=${tuple[1]}
key_frame=$(($experiment_length-1))
input_folder="@CMAKE_MNS_DATA_PATH@/exp_01_formation/$experiment_type/run_data/run1/logs"

if [[ $experiment_type == "cube_1000" ]]; then
	input_folder="@CMAKE_MNS_DATA_PATH@/exp_00_important_512_1000_drone_demos/cube_1000/logs"
fi

python3 @CMAKE_CURRENT_BINARY_DIR@/replay.py\
	-i $input_folder \
	-t \
	-k "$key_frame" \
	-e $experiment_length \
	-q $experiment_length \
	-c $camera \
	-m 32

