#!/bin/bash

# Script to install, remove, or upgrade vcpkg packages with cross-compilation triplets
# Usage: ./buildlib.sh install [--recurse] <library_name> [<library_name> ...]
#        ./buildlib.sh remove  [--recurse] <library_name> [<library_name> ...]
#        ./buildlib.sh upgrade
# DYM

RECURSE=0
POSITIONAL=()

# Parse options from anywhere in the argument list
for arg in "$@"; do
    case "$arg" in
        --recurse) RECURSE=1 ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done

ACTION=${POSITIONAL[0]}

if [ "$ACTION" != "install" ] && [ "$ACTION" != "remove" ] && [ "$ACTION" != "upgrade" ]; then
    echo "Error: Action must be 'install', 'remove', or 'upgrade'"
    echo "Usage: $0 {install|remove} [--recurse] <library_name> [<library_name> ...]"
    echo "       $0 upgrade"
    exit 1
fi

if [ "$ACTION" == "upgrade" ]; then
    if [ ${#POSITIONAL[@]} -gt 1 ]; then
        echo "Error: upgrade action does not accept library arguments"
        echo "Usage: $0 upgrade"
        exit 1
    fi
    LIBRARIES=()
else
    if [ ${#POSITIONAL[@]} -lt 2 ]; then
        echo "Usage: $0 {install|remove} [--recurse] <library_name> [<library_name> ...]"
        exit 1
    fi
    LIBRARIES=("${POSITIONAL[@]:1}")
fi

# Build recurse flag for vcpkg commands
RECURSE_FLAG=""
if [ "$RECURSE" -eq 1 ]; then
    RECURSE_FLAG="--recurse"
fi

# Define triplets (without .cmake extension, as used by vcpkg --triplet)
TRIPLETS=(
    "cross-x64-linux-x86"
    "cross-mips64-linux-x86"
    "cross-loongarch64-linux-x86"
    "cross-loongarch64-linux-x86-newworld"
    "cross-aarch64-linux-x86"
)

# VCPKG root directory is current directory
VCPKG_ROOT="."
VCPKG_EXE="${VCPKG_ROOT}/vcpkg_x86"

# Check if vcpkg exists
if [ ! -f "$VCPKG_EXE" ]; then
    echo "Error: vcpkg executable not found at $VCPKG_EXE"
    echo "Please set VCPKG_ROOT or ensure vcpkg is in the current directory"
    exit 1
fi

# Process each triplet
for triplet in "${TRIPLETS[@]}"; do
    triplet_file="${triplet}.cmake"

    echo "========================================="
    echo "Processing triplet: $triplet"
    echo "========================================="

    if [ "$ACTION" == "upgrade" ]; then
        echo "Upgrading all packages for $triplet..."
        "$VCPKG_EXE" upgrade --no-dry-run --triplet="$triplet"
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to upgrade packages for $triplet"
        fi
    else
        for LIBRARY_NAME in "${LIBRARIES[@]}"; do
            if [ "$ACTION" == "install" ]; then
                echo "Installing $LIBRARY_NAME for $triplet..."
                "$VCPKG_EXE" install "$LIBRARY_NAME" --triplet="$triplet" --no-binarycaching $RECURSE_FLAG
                if [ $? -ne 0 ]; then
                    echo "Warning: Failed to install $LIBRARY_NAME for $triplet"
                fi
            elif [ "$ACTION" == "remove" ]; then
                echo "Removing $LIBRARY_NAME for $triplet..."
                "$VCPKG_EXE" remove "$LIBRARY_NAME" --triplet="$triplet" $RECURSE_FLAG
                if [ $? -ne 0 ]; then
                    echo "Warning: Failed to remove $LIBRARY_NAME for $triplet"
                fi
            fi
        done
    fi

    echo ""
done

echo "========================================="
if [ "$ACTION" == "upgrade" ]; then
    echo "Completed $ACTION operation"
else
    echo "Completed $ACTION operation for ${LIBRARIES[*]}"
fi
echo "========================================="

