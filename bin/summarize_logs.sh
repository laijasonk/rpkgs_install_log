#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv [-o summary.csv]"
    echo "       $0 -i input.csv [-t $(pwd)]"
    echo "Flags:"
    echo "       -i path to input csv file"
    echo "       -o OPTIONAL path to output summary csv"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:o:t:h" opt
do
    case $opt in
        i) input_csv="$(readlink -f ${OPTARG})" ;;
        o) summary_csv="$(readlink -f ${OPTARG})" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${input_csv}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Point to correct output file and reset
if [[ -z "${status_csv}" ]]
then
    status_csv="${log_dir}/_summary.csv"
fi
cat /dev/null > "${status_csv}"

# Loop through input csv file
#while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check pkg_covr pkg_test
while IFS=, read -r pkg_name pkg_version pkg_url pkg_source git_commit
do
    download_log="${log_dir}/download_${pkg_name}.txt"
    build_log="${log_dir}/build_${pkg_name}.txt"
    check_log="${log_dir}/check_${pkg_name}.txt"
    install_log="${log_dir}/install_${pkg_name}.txt"
    artifact_log="${log_dir}/artifact_${pkg_name}.txt"
    artifactcheck_log="${log_dir}/artifactcheck_${pkg_name}.txt"
    test_log="${log_dir}/test_${pkg_name}.txt"

    download_status=0
    build_status=0
    check_status=0
    install_status=0
    artifact_status=0
    artifactcheck_status=0
    test_status=0

    # Download log
    error1="$(cat ${download_log} | grep -c 'ERROR 404')"
    skip1="$(cat ${check_log} | grep -c ' skipped because ')"
    if [[ "${error1}" -gt 0 ]]
    then
        download_status=1
    fi
    if [[ ! -f "${download_log}" ]] || [[ "${skip1}" -gt 0 ]]
    then
        download_status=2
    fi

    # Build log
    error1="$(cat ${build_log} | grep -c 'ERROR:')"
    skip1="$(cat ${build_log} | grep -c ' skipped because ')"
    if [[ "${error1}" -gt 0 ]]
    then
        build_status=1
    fi
    if [[ ! -f "${build_log}" ]] || [[ "${skip1}" -gt 0 ]]
    then
        build_status=2
    fi
     
    # Check log
    error1="$(cat ${check_log} | grep -c 'neither a file nor directory')"
    error2="$(cat ${check_log} | grep -c 'ERROR:')"
    skip1="$(cat ${check_log} | grep -c ' skipped due to input ')"
    if [[ "${error1}" -gt 0 ]] || [[ "${error2}" -gt 0 ]]
    then
        check_status=1
    fi
    if [[ ! -f "${check_log}" ]] || [[ "${skip1}" -gt 0 ]]
    then
        check_status=2
    fi

    # Install log
    error1="$(cat ${install_log} | grep -c 'ERROR:')"
    if [[ "${error1}" -gt 0 ]]
    then
        install_status=1
    fi
    if [[ ! -f "${install_log}" ]]
    then
        install_status=2
    fi
       
    # Artifact status log
    error1="$(cat ${artifact_log} | grep -c 'Missing file')"
    if [[ "${error1}" -gt 0 ]]
    then
        artifact_status=1
    fi
    if [[ ! -f "${artifact_log}" ]]
    then
        artifact_status=2
    fi

    # Artifact check log
    error1="$(cat ${artifactcheck_log} | grep -c 'neither a file nor directory')"
    error2="$(cat ${artifactcheck_log} | grep -c 'ERROR:')"
    skip1="$(cat ${artifactcheck_log} | grep -c ' skipped due to input ')"
    if [[ "${error1}" -gt 0 ]] || [[ "${error2}" -gt 0 ]]
    then
        artifactcheck_status=1
    fi
    if [[ ! -f "${artifactcheck_log}" ]] || [[ "${skip1}" -gt 0 ]]
    then
        artifactcheck_status=2
    fi

    # Test log
    error1="$(cat ${test_log} | grep -c 'Error: Test failures')"
    error2="$(cat ${test_log} | grep -c 'Execution halted')"
    error3="$(cat ${test_log} | grep -c 'ERROR:')"
    skip1="$(cat ${test_log} | grep -c 'Error: No tests found')"
    skip2="$(cat ${test_log} | grep -c ' skipped due to input ')"
    if [[ "${error1}" -gt 0 ]] || [[ "${error2}" -gt 0 ]] || [[ "${error3}" -gt 0 ]]
    then
        test_status=1
    fi
    if [[ ! -f "${test_log}" ]] || [[ "${skip1}" -gt 0 ]] || [[ "${skip2}" -gt 0 ]]
    then
        test_status=2
    fi

    echo "${pkg_name},${pkg_version},${pkg_source},${download_status},${build_status},${check_status},${install_status},${artifact_status},${artifactcheck_status},${test_status}" >> "${status_csv}"
done < "${input_csv}"

