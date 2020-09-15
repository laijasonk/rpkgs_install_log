#!/usr/bin/env bash
#
# Remove old files
#

# Default values (TODO: add option flags?)
src_dir="./src"
build_dir="./build"
lib_dir="./libs-r"
check_dir="${src_dir}/_check/"
log_dir="./log"

# Source files
echo "Removing package source files: ${src_dir}"
mkdir -p "${src_dir}"
touch "${src_dir}/tmp.tar.gz"
rm -R "${src_dir}"/*.tar.gz

# Build files
echo "Removing build files: ${build_dir}"
mkdir -p "${build_dir}"
touch "${build_dir}/tmp"
rm -R "${build_dir}"/*

# Library files
echo "Removing local library files: ${lib_dir}"
mkdir -p "${lib_dir}"
touch "${lib_dir}/tmp"
rm -R "${lib_dir}"/*

# Check files
echo "Removing checked packages: ${check_dir}"
mkdir -p "${check_dir}"
touch "${check_dir}/tmp"
rm -R "${check_dir}"/*

# Log files
echo "Removing log files: ${log_dir}"
mkdir -p "${log_dir}"
touch "${log_dir}/tmp"
rm -R "${log_dir}"/*

# Nicer display
echo

