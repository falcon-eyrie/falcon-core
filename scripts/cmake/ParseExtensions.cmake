if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/extensions.yaml")
    if(NOT DEFINED IGNORE_EXTENSIONS OR NOT IGNORE_EXTENSIONS)
        message(STATUS "Found extensions.yaml")

        file(READ "${CMAKE_CURRENT_SOURCE_DIR}/extensions.yaml" yaml_content)

        string(REPLACE "\n" ";" yaml_lines "${yaml_content}")

        set(EXTENSION_NAMES "")
        set(INSTALLED_EXTENSIONS "")
        set(EXTENSION_PATHS "")
        set(current_ext_name "")

        # Skip the first "extensions:" key and capture only 2nd level extension names
        set(skip_extensions_section TRUE)

        # Track the number of top-level keys
        set(top_level_keys_count 0)

        foreach(line ${yaml_lines})
            string(STRIP ${line} line)

            # Skip empty lines and comments
            if(line MATCHES "^\\s*#.*" OR line MATCHES "^\\s*$")
                continue()
            endif()

            # Check for the first-level key "extensions:"
            if(line MATCHES "^extensions:$")
                math(EXPR top_level_keys_count "${top_level_keys_count} + 1")
                continue()  # Skip processing this line as we just found the "extensions:" key
            endif()

            # If we've already found a top-level key, it's an error
            if(top_level_keys_count GREATER 1)
                message(FATAL_ERROR "YAML file contains more than one top-level key. It should only have 'extensions:'.")
            endif()

            # Look for 2nd-level extension names
            if(line MATCHES "^\\s*([a-zA-Z0-9_-]+):\\s*$")
                set(current_ext_name "${CMAKE_MATCH_1}")
                list(APPEND EXTENSION_NAMES "${current_ext_name}")
            elseif(line MATCHES "^\\s*remote_location: (.+)$")
                set(remote_location "${CMAKE_MATCH_1}")
                set("${current_ext_name}_remote_location" "${remote_location}")
            elseif(line MATCHES "^\\s*local_path: (.+)$")
                set(local_path "${CMAKE_MATCH_1}")
                set("${current_ext_name}_local_path" "${local_path}")
            elseif(line MATCHES "^\\s*git_tag: (.+)$")
                set(git_tag "${CMAKE_MATCH_1}")
                set("${current_ext_name}_git_tag" "${git_tag}")
            endif()
        endforeach()

        if(EXTENSION_NAMES)
            message(STATUS "Found extensions:")
            foreach(ext_name ${EXTENSION_NAMES})
                message(STATUS "Extension: ${ext_name}")
            endforeach()
        else()
            message(STATUS "No extensions found in extensions.yaml")
        endif()

        foreach(ext_name ${EXTENSION_NAMES})
            # Get the local_path and remote_location for the extension
            set(remote_location "${${ext_name}_remote_location}")
            set(local_path "${${ext_name}_local_path}")
            set(git_tag "${${ext_name}_git_tag}")

            if(remote_location AND local_path)
                message(FATAL_ERROR "Extension ${ext_name} has both remote_location and local_path, which is invalid.")
            elseif(NOT remote_location AND NOT local_path)
                message(FATAL_ERROR "Extension ${ext_name} must have either remote_location or local_path.")
            endif()

            message(STATUS "${ext_name}_remote_location = ${remote_location}")
            message(STATUS "${ext_name}_local_path = ${local_path}")
            message(STATUS "${ext_name}_git_tag = ${git_tag}")

            if(remote_location OR local_path)
                if(ext_name IN_LIST INSTALLED_EXTENSIONS)
                    message(STATUS "Skip duplicate. Extension ${ext_name} already installed")
                    continue()
                endif()

                # Handle remote extensions
                if(remote_location)
                    if(git_tag)
                        FetchContent_Declare(
                            ${ext_name}
                            GIT_REPOSITORY ${remote_location}
                            GIT_SHALLOW ON
                            GIT_TAG ${git_tag}
                        )
                        message(STATUS "Declared ${ext_name} (version ${git_tag}) from ${remote_location}.")
                    else()
                        FetchContent_Declare(
                            ${ext_name}
                            GIT_REPOSITORY ${remote_location}
                            GIT_SHALLOW ON
                        )
                        message(STATUS "Declared ${ext_name} from ${remote_location}.")
                    endif()
                # Handle local extensions
                elseif(local_path)
                    string(TOUPPER ${ext_name} ext_name_upper)
                    get_filename_component(abs_local_path "${local_path}" ABSOLUTE)
                    message(STATUS "Resolved absolute path for ${ext_name}: ${abs_local_path}")

                    set(FETCHCONTENT_SOURCE_DIR_${ext_name_upper} ${abs_local_path})

                    FetchContent_Declare(
                        ${ext_name}
                        GIT_SHALLOW OFF
                        BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/${ext_name}-build"
                    )
                    message(STATUS "Declared ${ext_name} from local path ${local_path}.")
                endif()

                FetchContent_MakeAvailable(${ext_name})

                list(APPEND INSTALLED_EXTENSIONS ${ext_name})
                list(APPEND EXTENSION_PATHS ${${ext_name}_SOURCE_DIR})

                if(git_tag)
                    list(APPEND _extension_names "${ext_name} - ${local_path} - ${git_tag}")
                else()
                    list(APPEND _extension_names "${ext_name} - ${local_path} - default-branch")
                endif()
            else()
                message(STATUS "Extension ${ext_name} is missing either remote_location or local_path.")
            endif()

        endforeach()

    else()
        message(STATUS "IGNORE_EXTENSIONS is set to ON, skipping all extensions.")
    endif()
else()
    message(STATUS "No extensions.yaml found.")
endif()
