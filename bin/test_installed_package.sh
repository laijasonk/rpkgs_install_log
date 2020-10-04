#!/usr/bin/env bash
#
# Test packages with testthat
#

# Help message
function usage {
    echo "Usage: $0 -i pkg_name"
    echo
    echo "Flags:"
    echo "       -i name of package to be tested"
    exit 1
}

# Argument flag handling
while getopts "i:h" opt
do
    case $opt in
        i)
            pkg_name="${OPTARG}"
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
if [[ -z "${pkg_name}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh

# Test package
echo "Testing '${pkg_name}' with testthat"
test_log="${log_dir}/test_${pkg_name}.txt"
eval -- "${rscript} -e \"testthat::test_package('${pkg_name}', reporter='location'); testthat::test_package('${pkg_name}', reporter='check')\"" &> ${test_log}
echo "Results saved to '${test_log}'"

