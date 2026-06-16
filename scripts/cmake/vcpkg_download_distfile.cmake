function(z_vcpkg_check_hash result file_path sha512)
    file(SHA512 "${file_path}" file_hash)
    string(TOLOWER "${sha512}" sha512_lower)
    string(COMPARE EQUAL "${file_hash}" "${sha512_lower}" hash_match)
    set("${result}" "${hash_match}" PARENT_SCOPE)
endfunction()

function(z_vcpkg_download_distfile_test_hash file_path kind error_advice sha512 skip_sha512)
    if(_VCPKG_INTERNAL_NO_HASH_CHECK)
        # When using the internal hash skip, do not output an explicit message.
        return()
    endif()
    if(skip_sha512)
        message(STATUS "Skipping hash check for ${file_path}.")
        return()
    endif()

    set(hash_match OFF)
    z_vcpkg_check_hash(hash_match "${file_path}" "${sha512}")

    if(NOT hash_match)
        message(FATAL_ERROR
            "\nFile does not have expected hash:\n"
            "        File path: [ ${file_path} ]\n"
            "    Expected hash: [ ${sha512} ]\n"
            "      Actual hash: [ ${file_hash} ]\n"
            "${error_advice}\n")
    endif()
endfunction()

function(z_vcpkg_download_distfile_via_aria)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        "SKIP_SHA512"
        "FILENAME;SHA512"
        "URLS;HEADERS"
    )

    message(STATUS "Downloading ${arg_FILENAME}...")

    vcpkg_list(SET headers_param)
    foreach(header IN LISTS arg_HEADERS)
        vcpkg_list(APPEND headers_param "--header=${header}")
    endforeach()

    foreach(URL IN LISTS arg_URLS)
        debug_message("Download Command: ${ARIA2} ${URL} -o temp/${filename} -l download-${filename}-detailed.log ${headers_param}")
        vcpkg_execute_in_download_mode(
            COMMAND ${ARIA2} ${URL}
            -o temp/${arg_FILENAME}
            -l download-${arg_FILENAME}-detailed.log
            ${headers_param}
            OUTPUT_FILE download-${arg_FILENAME}-out.log
            ERROR_FILE download-${arg_FILENAME}-err.log
            RESULT_VARIABLE error_code
            WORKING_DIRECTORY "${DOWNLOADS}"
        )

        if ("${error_code}" STREQUAL "0")
            break()
        endif()
    endforeach()
    if (NOT "${error_code}" STREQUAL "0")
        message(STATUS
            "Downloading ${arg_FILENAME}... Failed.\n"
            "    Exit Code: ${error_code}\n"
            "    See logs for more information:\n"
            "        ${DOWNLOADS}/download-${arg_FILENAME}-out.log\n"
            "        ${DOWNLOADS}/download-${arg_FILENAME}-err.log\n"
            "        ${DOWNLOADS}/download-${arg_FILENAME}-detailed.log\n"
        )
        z_vcpkg_download_distfile_show_proxy_and_fail("${error_code}")
    else()
        z_vcpkg_download_distfile_test_hash(
            "${DOWNLOADS}/temp/${arg_FILENAME}"
            "downloaded file"
            "The file may have been corrupted in transit."
            "${arg_SHA512}"
            ${arg_SKIP_SHA512}
        )
        file(REMOVE
            ${DOWNLOADS}/download-${arg_FILENAME}-out.log
            ${DOWNLOADS}/download-${arg_FILENAME}-err.log
            ${DOWNLOADS}/download-${arg_FILENAME}-detailed.log
        )
        get_filename_component(downloaded_file_dir "${downloaded_file_path}" DIRECTORY)
        file(MAKE_DIRECTORY "${downloaded_file_dir}")
        file(RENAME "${DOWNLOADS}/temp/${arg_FILENAME}" "${downloaded_file_path}")
    endif()
endfunction()

function(vcpkg_download_distfile out_var)
    cmake_parse_arguments(PARSE_ARGV 1 arg
        "SKIP_SHA512;SILENT_EXIT;QUIET;ALWAYS_REDOWNLOAD"
        "FILENAME;SHA512"
        "URLS;HEADERS"
    )

    if(NOT DEFINED arg_URLS)
        message(FATAL_ERROR "vcpkg_download_distfile requires a URLS argument.")
    endif()
    if(NOT DEFINED arg_FILENAME)
        message(FATAL_ERROR "vcpkg_download_distfile requires a FILENAME argument.")
    endif()
    if(arg_SILENT_EXIT)
        message(WARNING "SILENT_EXIT no longer has any effect. To resolve this warning, remove SILENT_EXIT.")
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

    # Try aria2 first if available and not disabled
    if(NOT arg_DISABLE_ARIA2 AND _VCPKG_DOWNLOAD_TOOL STREQUAL "ARIA2" AND NOT EXISTS "${downloaded_file_path}")
        if (arg_SKIP_SHA512)
            set(OPTION_SKIP_SHA512 "SKIP_SHA512")
        endif()
        z_vcpkg_download_distfile_via_aria(
            "${OPTION_SKIP_SHA512}"
            FILENAME "${arg_FILENAME}"
            SHA512 "${arg_SHA512}"
            URLS "${arg_URLS}"
            HEADERS "${arg_HEADERS}"
        )
        set("${out_var}" "${downloaded_file_path}" PARENT_SCOPE)
        return()
    endif()

    # Fallback to vcpkg x-download
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
