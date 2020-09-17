#!/usr/bin/env bash
#
# Remove old files
#

# Default values (TODO: add option flags?)
src_dir="./src"
cran_dir="./src/cran"
github_dir="./src/github"
build_dir="./build"
lib_dir="./libs-r"
check_dir="./check"
log_dir="./log"
mkdir -p ./"${src_dir}" ./"${cran_dir}" ./"${github_dir}" ./"${build_dir}" ./"${lib_dir}" ./"${check_dir}" ./"${log_dir}"

# Source files
echo "Removing package source files: ${src_dir}"
touch ./"${src_dir}"/tmp.tar.gz ./"${cran_dir}"/tmp ./"${github_dir}"/tmp && \
    rm -R -- ./"${src_dir}"/*.tar.gz ./"${cran_dir}"/* ./"${github_dir}"/*

# Build files
echo "Removing build files: ${build_dir}"
touch ./"${build_dir}"/tmp && \
    rm -R -- ./"${build_dir}"/*

# Library files
echo "Removing local library files: ${lib_dir}"
touch ./"${lib_dir}"/tmp && \
    rm -R -- ./"${lib_dir}"/*

# Check files
echo "Removing checked packages: ${check_dir}"
touch ./"${check_dir}"/tmp && \
    rm -R -- ./"${check_dir}"/*

# Log files
echo "Removing log files: ${log_dir}"
touch "${log_dir}"/tmp && \
    rm -R -- "${log_dir}"/*

# Nicer display
echo

