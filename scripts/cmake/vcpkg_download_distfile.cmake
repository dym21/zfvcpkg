function(z_vcpkg_download_distfile out_var)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        "SKIP_SHA512;SILENT_EXIT;QUIET;ALWAYS_REDOWNLOAD"
        "FILENAME;SHA512"
        "URLS;HEADERS"
    )

    # SILENT_EXIT and QUIET are meaningless but accepting and ignoring them allows
    # vcpkg_download_distfile to pass through parameters without needing manipulation.
    if(NOT DEFINED arg_URLS)
        message(FATAL_ERROR "vcpkg_download_distfile requires a URLS argument.")
    endif()
    if(NOT DEFINED arg_FILENAME)
        message(FATAL_ERROR "vcpkg_download_distfile requires a FILENAME argument.")
    endif()
    # Note that arg_ALWAYS_REDOWNLOAD implies arg_SKIP_SHA512, and NOT arg_SKIP_SHA512 implies NOT arg_ALWAYS_REDOWNLOAD
    if(arg_ALWAYS_REDOWNLOAD AND NOT arg_SKIP_SHA512)
        message(FATAL_ERROR "ALWAYS_REDOWNLOAD requires SKIP_SHA512")
    endif()

    if(NOT arg_SKIP_SHA512 AND NOT DEFINED arg_SHA512)
        message(FATAL_ERROR "vcpkg_download_distfile requires a SHA512 argument.
If you do not know the SHA512, add it as 'SHA512 0' and retry.")
    elseif(arg_SKIP_SHA512 AND DEFINED arg_SHA512)
        message(FATAL_ERROR "SHA512 may not be used with SKIP_SHA512.")
    endif()

    if(_VCPKG_INTERNAL_NO_HASH_CHECK)
        set(arg_SKIP_SHA512 1)
    endif()

    if(NOT arg_SKIP_SHA512)
        if("${arg_SHA512}" STREQUAL "0")
            string(REPEAT 0 128 arg_SHA512)
        else()
            string(LENGTH "${arg_SHA512}" arg_SHA512_length)
            if(NOT "${arg_SHA512_length}" EQUAL "128" OR NOT "${arg_SHA512}" MATCHES "^[a-zA-Z0-9]*$")
                message(FATAL_ERROR "Invalid SHA512: ${arg_SHA512}.
    If you do not know the file's SHA512, set this to \"0\".")
            endif()

            string(TOLOWER "${arg_SHA512}" arg_SHA512)
        endif()
    endif()

    set(downloaded_file_path "${DOWNLOADS}/${arg_FILENAME}")

    get_filename_component(directory_component "${arg_FILENAME}" DIRECTORY)
    if ("${directory_component}" STREQUAL "")
        file(MAKE_DIRECTORY "${DOWNLOADS}")
    else()
        file(MAKE_DIRECTORY "${DOWNLOADS}/${directory_component}")
    endif()

    if(EXISTS "${downloaded_file_path}")
        if(arg_SKIP_SHA512)
            if(NOT arg_ALWAYS_REDOWNLOAD)
                if(NOT _VCPKG_INTERNAL_NO_HASH_CHECK)
                    message(STATUS "Skipping hash check and using cached ${arg_FILENAME}")
                endif()

                set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
                return()
            endif()
        else()
            # Note that NOT arg_SKIP_SHA512 implies NOT arg_ALWAYS_REDOWNLOAD
            file(SHA512 "${downloaded_file_path}" file_hash)
            if("${file_hash}" STREQUAL "${arg_SHA512}")
                message(STATUS "Using cached ${arg_FILENAME}")
                set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
                return()
            endif()

            # The existing file hash mismatches. Perhaps the expected SHA512 changed. Try adding the expected SHA512
            # into the file name and try again to hopefully not conflict.
            get_filename_component(filename_component "${arg_FILENAME}" NAME_WE)
            get_filename_component(extension_component "${arg_FILENAME}" EXT)
            string(SUBSTRING "${arg_SHA512}" 0 8 hash)
            set(arg_FILENAME "${filename_component}-${hash}${extension_component}")
            if (NOT "${directory_component}" STREQUAL "")
                set(arg_FILENAME "${directory_component}/${arg_FILENAME}")
            endif()

            set(downloaded_file_path "${DOWNLOADS}/${arg_FILENAME}")
            if(EXISTS "${downloaded_file_path}")
                if(_VCPKG_NO_DOWNLOADS)
                    set(advice_message "note: Downloads are disabled. Please ensure that the expected file is placed at ${downloaded_file_path} and retry.")
                else()
                    set(advice_message "note: You may be able to resolve this failure by redownloading the file. To do so, delete ${downloaded_file_path} and retry.")
                endif()

                file(SHA512 "${downloaded_file_path}" file_hash)
                if("${file_hash}" STREQUAL "${arg_SHA512}")
                    message(STATUS "Using cached ${arg_FILENAME}")
                    set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
                    return()
                endif()

                # Note that the extra leading spaces are here to prevent CMake from badly attempting to wrap this
                message(FATAL_ERROR
                    "  ${downloaded_file_path}: error: existing downloaded file had an unexpected hash\n"
                    "  Expected: ${arg_SHA512}\n"
                    "  Actual  : ${file_hash}\n"
                    "  ${advice_message}")
            endif()
        endif()
    endif()

    # vcpkg_download_distfile_ALWAYS_REDOWNLOAD only triggers when NOT _VCPKG_NO_DOWNLOADS
    # this could be de-morgan'd out but it's more clear this way
    if(_VCPKG_NO_DOWNLOADS)
        message(FATAL_ERROR "Downloads are disabled, but '${downloaded_file_path}' does not exist.")
    endif()

    # Prefer wget when it is available. The complete wget phase is limited to
    # ten attempts (across the supplied URLs); wget's connect/read timeout is
    # fifteen seconds and the process is configured for one attempt so the retry
    # policy remains controlled here. If wget is unavailable or all attempts
    # fail, fall back to vcpkg x-download below.
    find_program(Z_VCPKG_WGET_EXECUTABLE NAMES wget wget.exe)
    if(Z_VCPKG_WGET_EXECUTABLE)
        set(wget_download_succeeded OFF)
        list(LENGTH arg_URLS wget_url_count)
        foreach(wget_attempt RANGE 1 10)
            math(EXPR wget_url_index "(${wget_attempt} - 1) % ${wget_url_count}")
            list(GET arg_URLS ${wget_url_index} url)
            file(REMOVE "${downloaded_file_path}")

            set(wget_args
                "--connect-timeout=15"
                "--timeout=15"
                "--tries=1"
                "--no-verbose"
                "--output-document=${downloaded_file_path}"
            )
            foreach(header IN LISTS arg_HEADERS)
                list(APPEND wget_args "--header=${header}")
            endforeach()
            list(APPEND wget_args "${url}")

            execute_process(
                COMMAND "${Z_VCPKG_WGET_EXECUTABLE}" ${wget_args}
                WORKING_DIRECTORY "${DOWNLOADS}"
                RESULT_VARIABLE wget_result
                OUTPUT_VARIABLE wget_output
                ERROR_VARIABLE wget_error
            )

            if("${wget_result}" EQUAL "0" AND EXISTS "${downloaded_file_path}")
                set(wget_hash_valid ON)
                if(NOT arg_SKIP_SHA512 AND NOT "${arg_SHA512}" MATCHES "^0+$")
                    file(SHA512 "${downloaded_file_path}" wget_file_hash)
                    if(NOT "${wget_file_hash}" STREQUAL "${arg_SHA512}")
                        set(wget_hash_valid OFF)
                        message(STATUS "wget attempt ${wget_attempt}/10 downloaded an unexpected hash for ${arg_FILENAME}")
                    endif()
                endif()

                if(wget_hash_valid)
                    message(STATUS "Downloaded ${arg_FILENAME} with wget")
                    set(wget_download_succeeded ON)
                    break()
                endif()
            endif()

            file(REMOVE "${downloaded_file_path}")
            message(STATUS "wget attempt ${wget_attempt}/10 failed for ${arg_FILENAME}; retrying")
        endforeach()

        if(wget_download_succeeded)
            set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
            return()
        endif()

        message(STATUS "wget failed for ${arg_FILENAME}; falling back to vcpkg x-download")
    endif()

    vcpkg_list(SET params "x-download" "${arg_FILENAME}")
    foreach(url IN LISTS arg_URLS)
        vcpkg_list(APPEND params "--url=${url}")
    endforeach()

    foreach(header IN LISTS arg_HEADERS)
        list(APPEND params "--header=${header}")
    endforeach()

    if(arg_SKIP_SHA512)
        vcpkg_list(APPEND params "--skip-sha512")
    else()
        vcpkg_list(APPEND params "--sha512=${arg_SHA512}")
    endif()

    # Setting WORKING_DIRECTORY and passing the relative FILENAME allows vcpkg x-download to print
    # the full relative path if FILENAME has /s in it.
    vcpkg_execute_in_download_mode(COMMAND "$ENV{VCPKG_COMMAND}" ${params} RESULT_VARIABLE error_code WORKING_DIRECTORY "${DOWNLOADS}")
    if(NOT "${error_code}" EQUAL "0")
        message(FATAL_ERROR "Download failed, halting portfile.")
    endif()

    set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
endfunction()

function(vcpkg_download_distfile out_var)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        "SKIP_SHA512;SILENT_EXIT;QUIET;ALWAYS_REDOWNLOAD"
        "FILENAME;SHA512"
        "URLS;HEADERS"
    )
    if(DEFINED arg_UNPARSED_ARGUMENTS)
        # backcompat needed to be preserved for
        # https://github.com/microsoft/vcpkg/blob/68b3d3404d0bc6f2a2287f64ed5f6aa777e70d56/ports/liblas/portfile.cmake#L9
        message("${Z_VCPKG_BACKCOMPAT_MESSAGE_LEVEL}" "vcpkg_download_distfile was passed extra arguments: ${arg_UNPARSED_ARGUMENTS}")
    endif()
    if(arg_SILENT_EXIT)
        message(WARNING "SILENT_EXIT no longer has any effect. To resolve this warning, remove SILENT_EXIT.")
    endif()

    z_vcpkg_function_arguments(forwarded_args 1)
    z_vcpkg_download_distfile("${out_var}" ${forwarded_args})
    set("${out_var}" "${${out_var}}" PARENT_SCOPE)

    list(GET arg_URLS 0 spdx_download_location)
    z_vcpkg_add_spdx_resource(
        NAME "${arg_FILENAME}"
        FILENAME "${arg_FILENAME}"
        DOWNLOAD_LOCATION "${spdx_download_location}"
        SHA512 "${arg_SHA512}"
    )
endfunction()
