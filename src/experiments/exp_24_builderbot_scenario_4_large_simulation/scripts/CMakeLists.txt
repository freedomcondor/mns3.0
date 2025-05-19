add_executable(joystick_exp24 joystick.cpp)

configure_file( evaluator.in.lua            evaluator.lua)
configure_file( drawLines.in.py             drawLines.py)
configure_file( drawLines_plot.in.py        drawLines_plot.py)

configure_file( run_threads.in.sh           run_threads.sh    @ONLY)
configure_file( eva_threads.in.sh           eva_threads.sh    @ONLY)