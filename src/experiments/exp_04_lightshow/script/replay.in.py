replayerFile = "@CMAKE_BINARY_DIR@/scripts/libreplayer/replayer.py"
#execfile(createArgosFileName)
exec(compile(open(replayerFile, "rb").read(), replayerFile, 'exec'))

#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/replayer_template.argos",
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["MULTITHREADS",      str(MultiThreads)],  # MultiThreads is inherit from createArgosScenario.py
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, "50,50,50,0", True)],
        ["ARENA_SIZE",        arena_size_xml], 
        ["ARENA_CENTER",      arena_center_xml], 
    ]
)

os.system("argos3 -c replay.argos")