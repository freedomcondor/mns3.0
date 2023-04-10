pythonPath=@CMAKE_CURRENT_BINARY_DIR@/simu_code/run.py
currentPath=`pwd`
runPath=scalability_test

mkdir $runPath
cd $runPath

for i in 5 10 15 20 25 30
do
	echo running $i
	mkdir $i

	cd $i
	python3 $pythonPath -l $i -v false
	cd ..
done

cd $currentPath
