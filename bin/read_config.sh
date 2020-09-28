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

# Conditions to run script
if [[ -z "${config_file}" ]]
then
    config_file="$(readlink -f ./config)"
else
    config_file="$(readlink -f ${config_file})"
fi
if [[ ! -f "${config_file}" ]]
then
    echo "ERROR: invalid config file '${config_file}'"
    exit 1
fi

# Load config variables and convert to absolute pathes
. ${config_file}

# Create directories if they do not exist
mkdir -p \
    "${lib_dir}" \
    "${src_dir}" \
    "${src_cran_dir}" \
    "${src_github_dir}" \
    "${build_dir}" \
    "${build_check_dir}" \
    "${html_dir}" \
    "${html_template}" \
    "${log_dir}" \
    "${check_dir}"

# Change any relative paths to absolute paths
export lib_dir="$(readlink -f ${lib_dir})"
export src_dir="$(readlink -f ${src_dir})"
export src_cran_dir="$(readlink -f ${src_cran_dir})"
export src_github_dir="$(readlink -f ${src_github_dir})"
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
check_variables src_cran_dir "${src_cran_dir}"
check_variables src_github_dir "${src_github_dir}"
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

