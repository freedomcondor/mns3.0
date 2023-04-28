pythonPath=@CMAKE_CURRENT_BINARY_DIR@/../simu_code/run.py
currentPath=`pwd`
runPath=scalability_test

mkdir $runPath
cd $runPath

for i in 20 40 60 80 100 120 140 160 180 200
do
	echo running $i
	mkdir $i

	cd $i
	timeout 3600 python3 $pythonPath -l $i -v false
	cd ..
done

cd $currentPath
