#!/usr/bin/env bash
#
# Set the global variables used across all scripts
#
# NOTE: This used to allow user-defined configs, but was removed to
#       minimize user-error
#

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 [-t $(pwd)]"
    echo "Flags:"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "t:h" opt
do
    case $opt in
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

function assign_arg_variables() {
    varfile="${1}"
    vardefault="${2}"

    if [[ ! -f "${varfile}" ]]
    then
        echo "${vardefault}"
    else
        cat "${varfile}"
    fi
}

function run_and_log_cmd() {
    cmd="${1}"
    log="${2}"
    echo -e "CMD: ${cmd}\n----------\n\n" > "${log}"
    eval -- "${cmd}" >> "${log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${log}"
}

# Conditions to run script
if [[ -z "${target_dir}" ]]
then
    target_dir="$(pwd)"
fi
mkdir -p "${target_dir}"
export target_dir="$(readlink -f ${target_dir})"

# Path to install libraries to (e.g. ./libs-r)
lib_dir="${target_dir}/libs"

# Path to store source files (e.g. ./src)
src_dir="${target_dir}/buildfiles/src"

# Path to store build tarballs and check metadata (e.g. ./build, ./build/check)
build_dir="${target_dir}/build"
build_check_dir="${target_dir}/build"

# Path to directories containing check info (e.g. ./check)
check_dir="${target_dir}/buildfiles/check"

# Path to direcotyr containing raw logs (e.g. ./log)
log_dir="${target_dir}/buildfiles/rawlog"

# Path to html logs (e.g. ./layer1_log)
html_dir="${target_dir}/log"

# Path to HTML template for logs (e.g. ./bin/html_generator/template)
html_template="./bin/html_generator/template"

# Create directories if they do not exist
mkdir -p \
    "${target_dir}" \
    "${lib_dir}" \
    "${src_dir}" \
    "${build_dir}" \
    "${build_check_dir}" \
    "${html_dir}" \
    "${html_template}" \
    "${log_dir}" \
    "${check_dir}"

# Change any relative paths to absolute paths
export lib_dir="$(readlink -f ${lib_dir})"
export src_dir="$(readlink -f ${src_dir})"
export build_dir="$(readlink -f ${build_dir})"
export build_check_dir="$(readlink -f ${build_check_dir})"
export html_dir="$(readlink -f ${html_dir})"
export html_template="$(readlink -f ${html_template})"
export log_dir="$(readlink -f ${log_dir})"
export check_dir="$(readlink -f ${check_dir})"

# Handle argument variables
export rlibs="$(assign_arg_variables ${log_dir}/_rlibs.txt /opt/bee_tools/R/3.6.1/lib64/R/library_sec:/opt/bee_tools/R/3.6.1/lib64/R/library)"
export rbinary="$(assign_arg_variables ${log_dir}/_rbinary.txt \"$(which R)\")"
export rscript="$(assign_arg_variables ${log_dir}/_rscript.txt \"$(which Rscript)\")"

# Set lib paths for R
export R_LIBS=${lib_dir}:${rlibs}

