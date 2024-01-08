drawDataFileName = "@CMAKE_SOURCE_DIR@/scripts/drawData.py"
#execfile(drawDataFileName)
exec(compile(open(drawDataFileName, "rb").read(), drawDataFileName, 'exec'))

import sys
import getopt
import os

from matplotlib.collections import PolyCollection

# Get experiment type
#--------------------------------------
usage="[usage] example: python3 xxx.py -t left"
try:
    optlist, args = getopt.getopt(sys.argv[1:], "t:h")
except:
    print("[error] unexpected opts")
    print(usage)
    sys.exit(0)

Experiment_type = None
for opt, value in optlist:
    if opt == "-t":
        Experiment_type = value
        print("Experiment_type provided: ", Experiment_type)
if Experiment_type == None :
    Experiment_type = "left"
    print("Experiment_type not provided: using default", Experiment_type)

ExperimentsDIR = "@CMAKE_MNS_DATA_PATH@/exp_02_race_track"
DATADIR = ExperimentsDIR + "/" + Experiment_type + "/run_data"

# check experiment type
#--------------------------------------
if not os.path.isdir(DATADIR) :
    print("Data folder doesn't exist : ", DATADIR)
    print("Existing Datafolder are : ")
    for subfolder in getSubfolders(ExperimentsDIR) :
        print("    " + subfolder)
    exit()

# read data sets
#--------------------------------------
data1Set = []
data2lSet = []
data2rSet = []
data3Set = []

for subfolder in getSubfolders(DATADIR) :
    data1Set.append(readDataFrom(subfolder + "result_data_1.txt"))
    data2lSet.append(readDataFrom(subfolder + "result_data_2_left.txt"))
    data2rSet.append(readDataFrom(subfolder + "result_data_2_right.txt"))
    data3Set.append(readDataFrom(subfolder + "result_data_3.txt"))

# start to draw
#--------------------------------------
ax = plt.axes(projection ='3d')
plt.gca().set_box_aspect((0.5,5,2))
ax.set_xticks([])  # Disable xticks
ax.view_init(20, -30)    # Z degree above ground    # X degree towards counterclockwise to the minus direction of X

width=8
margin=1

#----- data1 -----
data1StepsData, X = transferTimeDataToRunSetData(data1Set)
data1Mean, mini, maxi, upper, lower = calcMeanFromStepsData(data1StepsData)

drawRibbonDataInSubplot(data1Mean,      ax, {'color':'blue',       'width'    :width,          'dataStart':0                })
fill_between_3d(X, upper, lower, ax,        {'color':'black',      'zLocation':0,              'alpha'    :0.5,                 })
fill_between_3d(X, maxi,  mini,  ax,        {'color':'black',      'zLocation':0,              'alpha'    :0.3,                 })

#----- data2 left -----
data2LeftStepsData, X = transferTimeDataToRunSetData(data2lSet)
data2LeftMean, mini, maxi, upper, lower = calcMeanFromStepsData(data2LeftStepsData)
drawRibbonDataInSubplot(data2LeftMean,  ax, {'color':'red',        'width'    :width/2-margin, 'dataStart':len(data1StepsData),     'leading':data1Mean[-1]})
fill_between_3d(X, upper, lower, ax,        {'color':'black',      'zLocation':0,              'xStart'   :len(data1StepsData),     'alpha'  :0.5,        })
fill_between_3d(X, maxi,  mini,  ax,        {'color':'black',      'zLocation':0,              'xStart'   :len(data1StepsData),     'alpha'  :0.3,        })

#----- data2 right -----
data2RightStepsData, X = transferTimeDataToRunSetData(data2rSet)
data2RightMean, mini, maxi, upper, lower = calcMeanFromStepsData(data2RightStepsData)
drawRibbonDataInSubplot(data2RightMean,  ax, {'color':'green',     'width'    :width/2-margin,  'dataStart':len(data1StepsData),     'leading':data1Mean[-1],   'ribbonStart' : width/2+margin})
fill_between_3d(X, upper, lower, ax,         {'color':'black',     'zLocation':width/2+margin,  'xStart'   :len(data1StepsData),     'alpha'  :0.5,        })
fill_between_3d(X, maxi,  mini,  ax,         {'color':'black',     'zLocation':width/2+margin,  'xStart'   :len(data1StepsData),     'alpha'  :0.3,        })

#----- data3 -----
data3StepsData, X = transferTimeDataToRunSetData(data3Set)
data3Mean, mini, maxi, upper, lower = calcMeanFromStepsData(data3StepsData)
drawRibbonDataInSubplot(data3Mean,       ax, {'color':'blue',      'width'    :width,           'dataStart':len(data1StepsData) + len(data2LeftStepsData),     'leading':min(data2RightMean[-1],data2LeftMean[-1])})
fill_between_3d(X, upper, lower, ax,         {'color':'black',     'zLocation':0,               'xStart'   :len(data1StepsData) + len(data2LeftStepsData),     'alpha'  :0.5,        })
fill_between_3d(X, maxi,  mini,  ax,         {'color':'black',     'zLocation':0,               'xStart'   :len(data1StepsData) + len(data2LeftStepsData),     'alpha'  :0.3,        })

'''
# read before split
data1 = readDataFrom("result_data_1.txt")
drawRibbonDataInSubplot(data1,  ax, {'color' : 'blue',
                                     'width' : width,
                       })

# read after split left
data2l = readDataFrom("result_data_2_left.txt")
drawRibbonDataInSubplot(data2l, ax, {'color' : 'red',
                                     'width' : width/2-margin,
                                     'dataStart' : len(data1),
                                     'leading'   : data1[-1]
                       })

data2r = readDataFrom("result_data_2_right.txt")
drawRibbonDataInSubplot(data2r, ax, {'color' : 'green',
                                     'width' : width/2-margin,
                                     'dataStart' : len(data1),
                                     'ribbonStart' : width/2+margin,
                                     'leading'   : data1[-1]
                       })

# read after combine
data3 = readDataFrom("result_data_3.txt")
drawRibbonDataInSubplot(data3,  ax, {'color' : 'blue',
                                     'width' : width,
                                     'dataStart' : len(data1)+len(data2r),
                                     'leading'   : min(data2l[-1],data2r[-1])
                       })
'''

plt.show()
