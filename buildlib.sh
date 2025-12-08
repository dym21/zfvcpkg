#!/bin/bash

# Script to install or remove vcpkg packages with cross-compilation triplets
# Usage: ./buildlib.sh install <library_name> [<library_name> ...]
#        ./buildlib.sh remove  <library_name> [<library_name> ...]
# DYM

if [ $# -lt 2 ]; then
    echo "Usage: $0 {install|remove} <library_name> [<library_name> ...]"
    exit 1
fi

ACTION=$1
shift
LIBRARIES=("$@")

if [ "$ACTION" != "install" ] && [ "$ACTION" != "remove" ]; then
    echo "Error: Action must be 'install' or 'remove'"
    exit 1
fi

# Define triplets (without .cmake extension, as used by vcpkg --triplet)
TRIPLETS=(
    "cross-x64-linux-x86"
    "cross-mips64-linux-x86"
    "cross-loongarch64-linux-x86"
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
    
    for LIBRARY_NAME in "${LIBRARIES[@]}"; do
        if [ "$ACTION" == "install" ]; then
            echo "Installing $LIBRARY_NAME for $triplet..."
            "$VCPKG_EXE" install "$LIBRARY_NAME" --triplet="$triplet" --no-binarycaching
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to install $LIBRARY_NAME for $triplet"
            fi
        elif [ "$ACTION" == "remove" ]; then
            echo "Removing $LIBRARY_NAME for $triplet..."
            "$VCPKG_EXE" remove "$LIBRARY_NAME" --triplet="$triplet" --recurse
            if [ $? -ne 0 ]; then
                echo "Warning: Failed to remove $LIBRARY_NAME for $triplet"
            fi
        fi
    done
    
    echo ""
done

echo "========================================="
echo "Completed $ACTION operation for $LIBRARY_NAME"
echo "========================================="

