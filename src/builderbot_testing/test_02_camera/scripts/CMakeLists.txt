configure_file( copy_images_from_builderbot.in.sh
                copy_images_from_builderbot.sh
                @ONLY)

configure_file( calibrate.in.sh
                calibrate.sh
                @ONLY)

configure_file( calibration_input.xml
                calibration_input.xml
                @ONLY)

configure_file( create_intrinsic_calibration_file.py
                create_intrinsic_calibration_file.py
              )

configure_file( update_extrinsic_calibration_file.py
                ../hw_code/update_extrinsic_calibration_file.py
              )

#add_subdirectory(opencv_camera_calibration)