#!/usr/bin/env bash
#
# Remove old files
#

# Default values (TODO: add option flags?)
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
lib_dir="$(readlink -f ./libs-r)"
check_dir="$(readlink -f ./check)"
log_dir="$(readlink -f ./log)"

# Source files
echo "Removing package source files: ${src_dir}"
mkdir -p "${src_dir}" 
cran_dir="$(readlink -f ./src/cran)"
github_dir="$(readlink -f ./src/github)"
mkdir -p "${cran_dir}" "${github_dir}"
touch "${src_dir}/*.tar.gz" "${cran_dir}/tmp" "${github_dir}/tmp" && \
    rm -R "${src_dir}"/*.tar.gz "${cran_dir}"/* "${github_dir}"/*

# Build files
echo "Removing build files: ${build_dir}"
mkdir -p "${build_dir}"
touch "${build_dir}/tmp" && \
    rm -R "${build_dir}"/*

# Library files
echo "Removing local library files: ${lib_dir}"
mkdir -p "${lib_dir}"
touch "${lib_dir}/tmp" && \
    rm -R "${lib_dir}"/*

# Check files
echo "Removing checked packages: ${check_dir}"
mkdir -p "${check_dir}"
touch "${check_dir}/tmp" && \
    rm -R "${check_dir}"/*

# Log files
echo "Removing log files: ${log_dir}"
mkdir -p "${log_dir}"
touch "${log_dir}/tmp" && \
    rm -R "${log_dir}"/*

# Nicer display
echo

