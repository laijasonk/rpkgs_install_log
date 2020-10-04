#!/usr/bin/env bash
#
# Remove old files
#

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 [-t $(pwd)]"
    echo "Flags:"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Default values
target_dir=$(pwd)

# Argument flag handling
while getopts "t:h" opt
do
    case $opt in
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${target_dir}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Log files
echo "Removing log files: ${log_dir}"
touch "${log_dir}"/tmp.tmp && \
    rm -R -- "${log_dir}"/[!_]*.*

# Source files
echo "Removing package source files: ${src_dir}"
touch "${src_dir}"/tmp.tar.gz && \
    rm -R -- "${src_dir}"/*.tar.gz

# Build files
echo "Removing build files: ${build_dir}"
touch "${build_dir}"/tmp.tar.gz && \
    rm -R -- "${build_dir}"/*.*

# Library files
echo "Removing local library files: ${lib_dir}"
touch "${lib_dir}"/tmp && \
    rm -R -- "${lib_dir}"/*

# Check files
echo "Removing checked packages: ${check_dir}"
touch "${check_dir}"/tmp && \
    rm -R -- "${check_dir}"/*

