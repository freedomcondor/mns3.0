replayerFile = "@CMAKE_BINARY_DIR@/scripts/replayer/replayer.py"
#execfile(createArgosFileName)
exec(compile(open(replayerFile, "rb").read(), replayerFile, 'exec'))

#----------------------------------------------------------------------------------------------
# generate argos file
generate_argos_file("@CMAKE_CURRENT_BINARY_DIR@/replayer/replayer_template.argos", 
                    "replay.argos",
    [
        ["RANDOMSEED",        str(Inputseed)],  # Inputseed is inherit from createArgosScenario.py
        ["TOTALLENGTH",       str((Experiment_length or 0)/5)],
        ["DRONES",            drone_xml], 
        ["PIPUCKS",           pipuck_xml], 
        ["SIMULATION_SETUP",  generate_physics_media_loop_visualization("@CMAKE_BINARY_DIR@", False, True)],
    ]
)

os.system("argos3 -c replay.argos")