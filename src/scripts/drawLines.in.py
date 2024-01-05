drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

drawData(readDataFrom("result_data.txt"))
if os.path.isfile("result_minimum_distances.txt") :
    drawData(readDataFrom("result_minimum_distances.txt"))

if os.path.isfile("SoNSNumber.txt") :
    drawData(readDataFrom("SoNSNumber.txt"))

plt.show()
