set(EXT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/extensions")

if(EXISTS "${EXT_DIR}" AND IS_DIRECTORY "${EXT_DIR}")
    message(STATUS "Scanning extensions directory...")

    file(GLOB subdirs RELATIVE "${EXT_DIR}" "${EXT_DIR}/*")

    foreach(ext_name ${subdirs})
        if(IS_DIRECTORY "${EXT_DIR}/${ext_name}")

            if(ext_name IN_LIST INSTALLED_EXTENSIONS)
                message(STATUS "Skip duplicate. Extension ${ext_name} already installed")
                continue()
            endif()

            set(abs_ext_path "${EXT_DIR}/${ext_name}")
            message(STATUS "Found extension: ${ext_name} at ${abs_ext_path}")

            list(APPEND _extension_names "${ext_name} - ${abs_ext_path} - local")
            list(APPEND EXTENSION_PATHS "${abs_ext_path}")
            list(APPEND INSTALLED_EXTENSIONS ${ext_name})

        endif()
    endforeach()
else()
    message(STATUS "No extensions folder found.")
endif()
