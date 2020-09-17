#!/usr/bin/env bash
#
# Check source packages
#

# Default values (TODO: add option flags)
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log)"
check_dir="$(readlink -f ./check)"
pkg_archive_log="${log_dir}/_package_archives.log"

# Help message
function usage {
    echo "Usage: $0 -i pkg_tarball"
    echo
    echo "Flags:"
    echo "       -i path to the source tarball (after R CMD build)"
    exit 1
}

# Argument flag handling
while getopts "i:" opt
do
    case $opt in
        i)
            pkg_tarball="${OPTARG}"
            ;;
        :)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Package name must be provided
if [[ -z "${pkg_tarball}" ]]
then
    usage
fi

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${src_dir}" "${build_dir}" "${log_dir}" "${check_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Define variables based on input
pkg_tarball="$(readlink -f ${pkg_tarball})"
pkg_name="$(basename ${pkg_tarball} | sed 's/_.*$//')"
check_log="${log_dir}/check_${pkg_name}.log"

# Check and log check of input package tarball
cd ${check_dir}
echo "Checking package '${pkg_name}'"
R CMD check "${pkg_tarball}" &> "${check_log}"
echo "Results saved to '${check_log}'"
echo

