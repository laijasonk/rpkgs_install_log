#!/usr/bin/env bash
#
# Check source packages
#

# Default values
artifactory=false

# Help message
function usage {
    echo "Usage: $0 -i pkg_tarball"
    echo "       $0 -i pkg_tarball [-t $(pwd)]"
    echo "Flags:"
    echo "       -i path to the source tarball (after R CMD build)"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:t:h" opt
do
    case $opt in
        i) pkg_tarball="$(readlink -f ${OPTARG})" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${pkg_tarball}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Define variables based on input
pkg_tarball="$(readlink -f ${pkg_tarball})"
pkg_name="$(basename ${pkg_tarball} | sed 's/_.*$//')"

# Define log files
check_cmd="${log_dir}/check_${pkg_name}_cmd.txt"
check_stdout="${log_dir}/check_${pkg_name}_stdout.txt"
check_stderr="${log_dir}/check_${pkg_name}_stderr.txt"
check_exit="${log_dir}/check_${pkg_name}_exit.txt"
build_check_cmd="${build_check_dir}/${pkg_name}_check_cmd.txt"
build_check_stdout="${build_check_dir}/${pkg_name}_check_stdout.txt"
build_check_stderr="${build_check_dir}/${pkg_name}_check_stderr.txt"
build_check_exit="${build_check_dir}/${pkg_name}_check_exit.txt"

# Check and log check of input package tarball
cd ${check_dir}
echo "Checking package '${pkg_name}'"
cmd="${rbinary} CMD check --library=${lib_dir} \"${pkg_tarball}\""
echo "${cmd}" > "${check_cmd}"
eval -- "${cmd}" 2> "${check_stdout}" 1> "${check_stderr}"
echo $? > "${check_exit}"
echo "Results saved to '${log_dir}/check_${pkg_name}_*.txt'"

# Copying files to artifactory
cp "${check_cmd}" "${build_check_cmd}"
cp "${check_stdout}" "${build_check_stdout}"
cp "${check_stderr}" "${build_check_stderr}"
cp "${check_exit}" "${build_check_exit}"
echo "Results copied to '${build_check_dir}/*_check_*.txt'"

