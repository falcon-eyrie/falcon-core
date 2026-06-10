message(STATUS "Scanning extensions/ directory...")

set(EXT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/extensions")

file(GLOB subdirs RELATIVE "${EXT_DIR}" "${EXT_DIR}/*")

foreach(ext_name ${subdirs})
    set(abs_ext_path "${EXT_DIR}/${ext_name}")
    message(STATUS "Found extension: ${ext_name} at ${abs_ext_path}")

    list(APPEND _extension_names "${ext_name} - ${abs_ext_path} - local")
    list(APPEND EXTENSION_PATHS "${abs_ext_path}")
    list(APPEND INSTALLED_EXTENSIONS ${ext_name})

endforeach()