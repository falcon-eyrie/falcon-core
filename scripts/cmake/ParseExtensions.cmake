
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/extensions.txt")
	if(NOT DEFINED IGNORE_EXTENSIONS OR NOT IGNORE_EXTENSIONS)
		message(STATUS "Found extensions.txt")

		file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/extensions.txt" extensions)

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
				include_directories(BEFORE SYSTEM "${$ext_name}_SOURCE_DIR}" ${${ext_name}_BINARY_DIR}/include)

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
	else()
		message(STATUS "IGNORE_EXTENSION is set to ON, skipping all extensions")
	endif()
else()
	message(STATUS "No extensions found.")
endif()
