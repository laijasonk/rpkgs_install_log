#!/usr/bin/env bash
#
# Test packages with testthat
#

# Help message
function usage {
    echo "Usage: $0 -i pkg_name"
    echo "       $0 -i pkg_name [-c config]"
    echo "Flags:"
    echo "       -i name of package to be tested"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "i:c:h" opt
do
    case $opt in
        i)
            pkg_name="${OPTARG}"
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
if [[ -z "${pkg_name}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"

# Test package
echo "Testing '${pkg_name}' with testthat"
testthat_log="${log_dir}/testthat_${pkg_name}.txt"
Rscript -e "testthat::test_package(\"${pkg_name}\", reporter=\"location\"); testthat::test_package(\"${pkg_name}\", reporter=\"check\")" &> ${testthat_log}
echo "Results saved to '${testthat_log}'"
echo

