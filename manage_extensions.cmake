MACRO(SUBDIRLIST result curdir)
    FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
    SET(dirlist "")
    FOREACH (child ${children})
        IF (IS_DIRECTORY ${curdir}/${child})
            LIST(APPEND dirlist ${child})
        ENDIF ()
    ENDFOREACH ()
    SET(${result} ${dirlist})
ENDMACRO()

MACRO (select_extensions extension_file)
	message(STATUS "Found extensions.txt")
	file(STRINGS ${extension_file} extensions)
	# remove header row
	list(REMOVE_AT extensions 0)
	list(LENGTH extensions nextensions)
	message(STATUS "Found ${nextensions} extensions.")

	foreach(ext ${extensions})
		
		# convert from comma separated string to list
		string(REPLACE " " "" ext ${ext})
		string(REPLACE "," ";" ext ${ext})
		list(LENGTH ext nitems)

		# we need at least enabled, name and path
		if (nitems LESS 3)
			continue()
		endif()

		# only add enabled extensions
		list(GET ext 0 ext_enabled)
		list(GET ext 1 ext_name)
		list(GET ext 2 ext_path)

		if(ext_enabled)
			if(ext_name IN_LIST INSTALLED_EXTENSIONS)
				message(STATUS "Skip duplicate. Extension ${ext_name} already installed")
				continue()
			endif()

			if(ext_enabled STREQUAL "dev")
				string(TOUPPER ${ext_name} ext_name_upper)
				SET(FETCHCONTENT_SOURCE_DIR_${ext_name_upper} ${ext_path})
				message(STATUS "Adding ${ext_name} in development mode.")
			endif()

			# check if optional version is given
			if (nitems GREATER_EQUAL 4)	
				list(GET ext 3 ext_version)
				FetchContent_Declare(
					${ext_name}
					GIT_REPOSITORY ${ext_path}
					GIT_SHALLOW	ON
					GIT_TAG ${ext_version}
				)
				message(STATUS "Declared ${ext_name} (version ${ext_version}) at ${ext_path}.")
			else()
				FetchContent_Declare(
					${ext_name}
					GIT_REPOSITORY ${ext_path}
					GIT_SHALLOW	ON
				)
				message(STATUS "Declared ${ext_name} at ${ext_path}.")
				set(ext_version "master-branch")
			endif()
			
			# populate
			FetchContent_GetProperties(${ext_name})
			if(NOT ${ext_name}_POPULATED)
				message(STATUS "Populating ${ext_name} ...")
				FetchContent_Populate(${ext_name})
				add_subdirectory(${${ext_name}_SOURCE_DIR} ${${ext_name}_BINARY_DIR})
				message(STATUS "Done.")
			endif()

			include_directories(BEFORE SYSTEM "${${ext_name}_SOURCE_DIR}" ${${ext_name}_BINARY_DIR}/include)

			if(ext_enabled STREQUAL "dev")
				list(APPEND _extension_names "${ext_name} - ${ext_path} - dev")
			else()
				list(APPEND _extension_names "${ext_name} - ${ext_path} - ${ext_version}")
			endif()
			
			# add to list of extensions
			list(APPEND EXTENSION_PATHS ${${ext_name}_SOURCE_DIR})

			# add to installed extensions
			list(APPEND INSTALLED_EXTENSIONS ${ext_name})
		
		else()
			message(STATUS "Extension ${ext_name} is not enabled. Skipped.")
		endif()

	endforeach()
	
ENDMACRO()

MACRO(import_extensions)
if (COMPILE_EXTENSIONS)
    set(DATATYPE_LIBS)
    set(PROCESSOR_LIBS)
    set(PROCESSOR_TEST)
    # get real absolute extension paths
    set(PROCESSOR_DOC)
    SET(REAL_FALCON_PATHS, "")

    foreach (FALCON_PATH ${EXTENSION_PATHS})
        get_filename_component(FALCON_PATH ${FALCON_PATH} REALPATH)
        LIST(APPEND REAL_FALCON_PATHS ${FALCON_PATH})
    endforeach ()

    # first, let's add all include directories
    foreach (FALCON_PATH ${REAL_FALCON_PATHS})

        MESSAGE("Adding include directories for extension: ${FALCON_PATH}")

        if (EXISTS ${FALCON_PATH}/lib)
            include_directories(${FALCON_PATH}/lib)
        endif ()

        if (EXISTS ${FALCON_PATH}/datatypes)
            include_directories(${FALCON_PATH}/datatypes)
        endif ()

        if (EXISTS ${FALCON_PATH}/processors)
            include_directories(${FALCON_PATH}/processors)
        endif ()

    endforeach ()

    # next, let's add all libs in extensions
    SET(ITER 0)

    foreach (FALCON_PATH ${REAL_FALCON_PATHS})
        if (EXISTS ${FALCON_PATH}/lib/CMakeLists.txt)
            MESSAGE("Adding libraries for extension: ${FALCON_PATH}")
            add_subdirectory(${FALCON_PATH}/lib ${CMAKE_CURRENT_BINARY_DIR}/lib${ITER})
        endif ()
        math(EXPR ITER "${ITER} + 1")
    endforeach ()

    # next, let's add all datatypes

    foreach (FALCON_PATH ${REAL_FALCON_PATHS})

        if (EXISTS ${FALCON_PATH}/datatypes)

            MESSAGE("Adding datatypes for extension: ${FALCON_PATH}")

            SUBDIRLIST(DATATYPES "${FALCON_PATH}/datatypes")

            set(EXCLUDED_ITEMS "")
            if (EXISTS ${FALCON_PATH}/datatypes/exclude.txt)
                FILE(STRINGS ${FALCON_PATH}/datatypes/exclude.txt EXCLUDED_ITEMS)
            endif ()

            FOREACH (DATATYPE ${DATATYPES})
                LIST(FIND EXCLUDED_ITEMS ${DATATYPE} DO_EXCLUDE)
                if (DO_EXCLUDE GREATER -1)
                    MESSAGE("Excluding data type: ${DATATYPE}")
                    continue()
                else ()
                    if (EXISTS "${FALCON_PATH}/datatypes/${DATATYPE}/CMakeLists.txt")
                        MESSAGE("Adding data type: ${DATATYPE}")
                        add_subdirectory(${FALCON_PATH}/datatypes/${DATATYPE} ${CMAKE_CURRENT_BINARY_DIR}/datatypes/${DATATYPE})
                        if (TARGET ${DATATYPE})
                            LIST(APPEND DATATYPE_LIBS ${DATATYPE})
                        endif ()

                    endif ()
                endif ()
            ENDFOREACH ()

        endif ()

    endforeach ()

    # then, let's add all processors

    foreach (FALCON_PATH ${REAL_FALCON_PATHS})

        if (EXISTS ${FALCON_PATH}/processors)

            MESSAGE("Adding processors for extension: ${FALCON_PATH}")

            SUBDIRLIST(PROCESSORS "${FALCON_PATH}/processors")

            set(EXCLUDED_ITEMS "")
            if (EXISTS ${FALCON_PATH}/processors/exclude.txt)
                FILE(STRINGS ${FALCON_PATH}/processors/exclude.txt EXCLUDED_ITEMS)
            endif ()

            FOREACH (PROCESSOR ${PROCESSORS})
                LIST(FIND EXCLUDED_ITEMS ${PROCESSOR} DO_EXCLUDE)
                if (DO_EXCLUDE GREATER -1)
                    MESSAGE("Excluding processor: ${PROCESSOR}")
                    continue()
                else ()
                    if (EXISTS "${FALCON_PATH}/processors/${PROCESSOR}/CMakeLists.txt")
                        MESSAGE("Adding processor: ${PROCESSOR}")
                       
                        add_subdirectory(${FALCON_PATH}/processors/${PROCESSOR} ${CMAKE_CURRENT_BINARY_DIR}/processors/${PROCESSOR})
                        
                        if (TARGET ${PROCESSOR})
		             LIST(APPEND PROCESSOR_LIBS ${PROCESSOR})
		        endif ()
		   
                        if(TARGET ${PROCESSOR}_test)
                             MESSAGE("Add test:  ${PROCESSOR}_test")
		             LIST(APPEND PROCESSOR_TEST ${PROCESSOR}_test)
		        endif ()


		        
                       if (EXISTS "${FALCON_PATH}/processors/${PROCESSOR}/doc.yaml")
                            configure_file(${FALCON_PATH}/processors/${PROCESSOR}/doc.yaml
                                    ${CMAKE_CURRENT_BINARY_DIR}/processors/${PROCESSOR} COPYONLY)
                        endif ()
                        
                        
                    endif ()
                endif ()
            ENDFOREACH ()

        endif ()

    endforeach ()
endif()
ENDMACRO()

MACRO(import_tools) 
if (COMPILE_EXTENSIONS)
    # and finally add all tools
    SET(ITER 0)

    foreach (FALCON_PATH ${REAL_FALCON_PATHS})

        if (EXISTS ${FALCON_PATH}/tools/CMakeLists.txt)
            MESSAGE("Adding tools from extension: ${FALCON_PATH}")
            add_subdirectory(${FALCON_PATH}/tools ${CMAKE_CURRENT_BINARY_DIR}/tools${ITER})
        endif ()

        math(EXPR ITER "${ITER} + 1")

    endforeach ()
endif()
ENDMACRO()


MACRO(import_resources)
if (COMPILE_EXTENSIONS)
    foreach (FALCON_PATH ${REAL_FALCON_PATHS})
       
        if (EXISTS ${FALCON_PATH}/resources)
            MESSAGE("Adding resources for extension: ${FALCON_PATH}")
            include_directories(${FALCON_PATH}/resources)
        endif ()
        FILE(GLOB RESOURCES RELATIVE ${FALCON_PATH}/resources ${FALCON_PATH}/resources/*)
        ADD_CUSTOM_COMMAND(TARGET falcon
                POST_BUILD
                COMMAND mkdir -p ${BUILD_RESOURCES_PATH}/resources/${RESOURCE}
                )
        foreach (RESOURCE ${RESOURCES})
            ADD_CUSTOM_COMMAND(TARGET falcon
                    POST_BUILD
                    COMMAND cp -r ${FALCON_PATH}/resources/${RESOURCE} ${BUILD_RESOURCES_PATH}/resources/${RESOURCE}/
                    )

        endforeach ()
    endforeach ()
    
    # install in the installation folder
    install(DIRECTORY ${BUILD_RESOURCES_PATH}/resources
            CONFIGURATIONS Release 
            DESTINATION ${RESOURCES_PATH})
endif()
ENDMACRO()


