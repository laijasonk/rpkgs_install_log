#!/usr/bin/env bash
#
# Remove old files
#

# Help message
function usage {
    echo "Usage: $0 [-c config]"
    echo
    echo "Flags:"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "c:h" opt
do
    case $opt in
        c)
            config_file="${OPTARG}"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"

# Log files
echo "Removing log files: ${log_dir}"
touch "${log_dir}"/tmp && \
    rm -R -- "${log_dir}"/*

# Source files
echo "Removing package source files: ${src_dir}"
touch "${src_dir}"/tmp.tar.gz "${src_github_dir}"/tmp && \
    rm -R -- "${src_dir}"/*.tar.gz "${src_github_dir}"/*

# Build files
echo "Removing build files: ${build_dir}"
touch "${build_dir}"/tmp && \
    rm -R -- "${build_dir}"/*

# Library files
echo "Removing local library files: ${lib_dir}"
touch "${lib_dir}"/tmp && \
    rm -R -- "${lib_dir}"/*

# Check files
echo "Removing checked packages: ${check_dir}"
touch "${check_dir}"/tmp && \
    rm -R -- "${check_dir}"/*

