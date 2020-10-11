#!/usr/bin/env bash
#
# Test packages with testthat
#

# Help message
function usage {
    echo "Usage: $0 -i pkg_name"
    echo "       $0 -i pkg_name [-t $(pwd)]"
    echo "Flags:"
    echo "       -i name of package to be tested"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:t:h" opt
do
    case $opt in
        i) pkg_name="${OPTARG}" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${pkg_name}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Test package
echo "Testing '${pkg_name}' with testthat"
test_log="${log_dir}/test_${pkg_name}.txt"
test_dir="${lib_dir}/${pkg_name}/test"
cmd="${rscript} -e \"testthat::test_dir('${test_dir}')\""
echo -e "CMD: ${cmd}\n----------\n\n" > "${test_log}"
eval -- "${cmd}" >> "${test_log}" 2>&1
echo -e "\n\n----------\nExit status: $?">> "${test_log}"
echo "Results saved to '${test_log}'"

