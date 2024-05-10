#----------------------------------------------------------------------------------------------
# usage message 
usage=\
"[usage] example: bash copy_images_from_drone.sh -i root@192.168.1.103:/media/usb/(remember a \"/\" at last) -s images(folder name) -t temp(folder name)"
echo $usage

#----------------------------------------------------------------------------------------------
# check flags
while getopts "i:a:s:h" arg; do
	case $arg in
		i)
			echo "ip provided: $OPTARG"
			drone_ip=$OPTARG
			;;
		s)
			echo "save folder provided: $OPTARG"
			save_folder=$OPTARG
			;;
		h)
			exit
	esac
done

#----------------------------------------------------------------------------------------------
# default value
if [ -z "$drone_ip" ]; then
	drone_ip="root@192.168.1.103:/home/root/saveImage/"
	echo "ip not provided, use $drone_ip by default"
fi
if [ -z "$save_folder" ]; then
	save_folder="images"
	echo "save folder not provided, use $save_folder by default"
fi
if [ -z "$temp_folder" ]; then
	temp_folder="temp"
	echo "temp folder not provided, use $temp_folder by default"
fi

#----------------------------------------------------------------------------------------------
# create temp folder
if [ -d "$temp_folder" ]; then
	echo "[Warning] $temp_folder folder exist! Overwrite by default"
	rm -r $temp_folder
fi
mkdir $temp_folder

#----------------------------------------------------------------------------------------------
# copy pnms from the drone
echo "Copying pnms from the drone"
pnm_name="*.pnm"
scp $drone_ip$pnm_name $temp_folder

# check temp_folder empty
if [ "`ls -A $temp_folder`" = "" ]; then
	echo "[Error] Nothing copied, maybe check ip address or confirm that there are images on the builderbot?"
	echo "[Error] Attempted location is $drone_ip$pnm_name"
	rm -r $temp_folder
	exit
fi

echo "Converting pnms to pngs"
for f in $temp_folder/*.pnm
do
	base=${f%.*}
	if [ -s ${base}.pnm ]; then
		pnmtopng ${base}.pnm > ${base}.png
	else
		echo "${base}.pnm is empty"
	fi
done
rm $temp_folder/*.pnm

#----------------------------------------------------------------------------------------------
# sort images
#  create save folder
if [ -d "$save_folder" ]; then
	echo "[Warning] $save_folder folder exist! Overwrite by default"
	rm -r $save_folder
fi
mkdir $save_folder
mv $temp_folder/*.png $save_folder/
	