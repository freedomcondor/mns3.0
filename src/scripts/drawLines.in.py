drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

drawData(readDataFrom("result_data.txt"))
#drawData(readDataFrom("result_minimum_distances.txt"))

plt.show()