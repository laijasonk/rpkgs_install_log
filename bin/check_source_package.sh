#!/usr/bin/env bash
#
# Check source packages
#

# Default values
artifactory=false

# Help message
function usage {
    echo "Usage: $0 -i pkg_tarball"
    echo "       $0 -i pkg_tarball [-c config]"
    echo
    echo "Flags:"
    echo "       -i path to the source tarball (after R CMD build)"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "i:ac:h" opt
do
    case $opt in
        i)
            pkg_tarball="$(readlink -f ${OPTARG})"
            ;;
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
if [[ -z "${pkg_tarball}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"

# Define variables based on input
pkg_tarball="$(readlink -f ${pkg_tarball})"
pkg_name="$(basename ${pkg_tarball} | sed 's/_.*$//')"

# Define log files
check_log="${log_dir}/check_${pkg_name}.txt"
build_check_log="${build_check_dir}/${pkg_name}.txt"

# Check and log check of input package tarball
cd ${check_dir}
echo "Checking package '${pkg_name}'"
R CMD check "${pkg_tarball}" &> "${check_log}"
echo "Results saved to '${check_log}'"

# Copying files to artifactory
cp "${check_log}" "${build_check_log}"
echo "Results copied to '${build_check_log}'"

