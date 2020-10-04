#!/usr/bin/env bash
#
# Read config file
#

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 [-c config]"
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

# Path to install libraries to (e.g. ./libs-r)
lib_dir="./libs"

# Path to export for R_LIBS_USER (e.g. /home/user/libs:/home/user/libs2)
r_libs_user="./libs"

# Path to store source files (e.g. ./src)
src_dir="./buildfiles/src"

# Path to store build tarballs and check metadata (e.g. ./build, ./build/check)
build_dir="./artifactory"
build_check_dir="./artifactory"

# Path to directories containing check info (e.g. ./check)
check_dir="./buildfiles/check"

# Path to store raw logs (e.g. ./build/log)
log_dir="./artifactory/log"

# Path to html logs (e.g. ./layer1_log)
html_dir="./log"

# Path to HTML template for logs (e.g. ./bin/html_generator/template)
html_template="./bin/html_generator/template"

# External repo (e.g. http://cran.r-project.org)
external_repo="http://cran.r-project.org"

# Create directories if they do not exist
mkdir -p \
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

# Function to identify errors
function check_variables() {
    if [[ -z "${2}" ]]
    then
        echo "ERROR: missing '${1}' in config file '${config_file}'"
        exit 1
    fi
}

check_variables lib_dir "${lib_dir}"
check_variables r_libs_user "${r_libs_user}"
check_variables src_dir "${src_dir}"
check_variables build_dir "${build_dir}"
check_variables build_check_dir "${build_check_dir}"
check_variables html_dir "${html_dir}"
check_variables html_template "${html_template}"
check_variables log_dir "${log_dir}"
check_variables check_dir "${check_dir}"
check_variables external_repo "${external_repo}"

# Set lib paths for R
IFS=':' read -r -a lib_paths <<< "${r_libs_user}"
R_LIBS_USER=""
for lib_path in "${lib_paths[@]}"
do
    export R_LIBS_USER="${R_LIBS_USER}:$(readlink -f ${lib_path})"
done

