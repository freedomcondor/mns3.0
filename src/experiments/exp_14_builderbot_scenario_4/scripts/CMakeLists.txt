configure_file( evaluator.in.lua            evaluator.lua)
configure_file( drawLines.in.py             drawLines.py)

configure_file( replay.in.py                replay.py)
configure_file( replayer_template.in.argos  replayer_template.argos)

add_executable(joystick joystick.cpp)