#!/usr/bin/env bash
#
# Test packages with testthat
#

# Default values
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log/raw)"

# Help message
function usage {
    echo "Usage: $0 -i pkg_name"
    echo
    echo "Flags:"
    echo "       -i name of package to be tested"
    exit 1
}

# Argument flag handling
while getopts "i:" opt
do
    case $opt in
        i)
            pkg_name="${OPTARG}"
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
if [[ -z "${pkg_name}" ]]
then
    usage
fi

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${src_dir}" "${build_dir}" "${log_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Test package
echo "Testing '${pkg_name}' with testthat"
testthat_log="${log_dir}/testthat_${pkg_name}.txt"
Rscript -e "testthat::test_package(\"${pkg_name}\", reporter=\"location\"); testthat::test_package(\"${pkg_name}\", reporter=\"check\")" &> ${testthat_log}
echo "Results saved to '${testthat_log}'"
echo

