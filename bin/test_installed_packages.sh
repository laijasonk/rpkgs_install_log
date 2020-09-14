#!/usr/bin/env bash
#
# Test packages with testthat
#

# Default values
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log)"

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo
    echo "Flags:"
    echo "       -i input CSV containing a package on each newline"
    exit 1
}

# Argument flag handling
while getopts "i:" opt
do
    case $opt in
        i)
            input_csv="${OPTARG}"
            ;;
        :)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Input CSV must be provided
if [[ -z "${input_csv}" ]]
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

# Test every package in input csv
while IFS=, read -r pkg_name pkg_version pkg_type pkg_url
do
    echo "Testing ${pkg_name} with testthat"
    testthat_log="${log_dir}/testthat_${pkg_name}.log"
    Rscript -e "testthat::test_package(\"${pkg_name}\", reporter=\"location\"); testthat::test_package(\"${pkg_name}\", reporter=\"check\")" &> ${testthat_log}
    echo "Results saved to ${testthat_log}"
    echo
done < "${input_csv}"

