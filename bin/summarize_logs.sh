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
while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check pkg_covr pkg_test
do
    download_log="${log_dir}/download_${pkg_name}.txt"
    artifact_log="${log_dir}/artifact_${pkg_name}.txt"
    test_log="${log_dir}/test_${pkg_name}.txt"
    
    build_stdout="${log_dir}/build_${pkg_name}_stdout.txt"
    build_stderr="${log_dir}/build_${pkg_name}_stderr.txt"
    build_exit="${log_dir}/build_${pkg_name}_exit.txt"
    check_stdout="${log_dir}/check_${pkg_name}_stdout.txt"
    check_stderr="${log_dir}/check_${pkg_name}_stderr.txt"
    check_exit="${log_dir}/check_${pkg_name}_exit.txt"
    install_stdout="${log_dir}/install_${pkg_name}_stdout.txt"
    install_stderr="${log_dir}/install_${pkg_name}_stderr.txt"
    install_exit="${log_dir}/install_${pkg_name}_exit.txt"
    artifactcheck_stdout="${log_dir}/artifactcheck_${pkg_name}_stdout.txt"
    artifactcheck_stderr="${log_dir}/artifactcheck_${pkg_name}_stderr.txt"
    artifactcheck_exit="${log_dir}/artifactcheck_${pkg_name}_exit.txt"

    download_status=0
    build_status=0
    check_status=0
    install_status=0
    artifact_status=0
    artifactcheck_status=0
    test_status=0

    # Download log
    status1="$(cat ${download_log} | grep -c 'ERROR 404')"
    if [[ "${status1}" -gt 0 ]]
    then
        download_status=1
    fi
    if [[ ! -f "${download_log}" ]]
    then
        download_status=2
    fi

    # Build log
    status1="$(cat ${build_stdout} | grep -c 'ERROR')"
    exit_status="$(cat ${build_exit})"
    if [[ "${status1}" -gt 0 ]] || [[ "${exit_status}" -ne 0 ]]
    then
        build_status=1
    fi
    if [[ ! -f "${build_cmd}" ]]
    then
        build_status=2
    fi
     
    # Check log
    status1="$(cat ${check_stderr} | grep -c 'neither a file nor directory')"
    status2="$(cat ${check_stderr} | grep -c 'ERROR')"
    exit_status="$(cat ${check_exit})"
    if [[ "${status1}" -gt 0 ]] || [[ "${status2}" -gt 0 ]] || [[ "${exit_status}" -ne 0 ]]
    then
        check_status=1
    fi
    if [[ ! -f "${check_cmd}" ]] || [[ "${pkg_check}" == "FALSE" ]]
    then
        check_status=2
    fi

    # Install log
    status1="$(cat ${install_stderr} | grep -c 'ERROR')"
    exit_status="$(cat ${install_exit})"
    if [[ "${status1}" -gt 0 ]] || [[ "${exit_status}" -ne 0 ]]
    then
        install_status=1
    fi
    if [[ ! -f "${install_cmd}" ]]
    then
        install_status=2
    fi
       
    # Artifact status log
    status1="$(cat ${artifact_log} | grep -c 'Missing file')"
    if [[ "${status1}" -gt 0 ]]
    then
        artifact_status=1
    fi
    if [[ ! -f "${artifact_log}" ]]
    then
        artifact_status=2
    fi

    # Artifact check log
    status1="$(cat ${artifactcheck_stderr} | grep -c 'neither a file nor directory')"
    status2="$(cat ${artifactcheck_stderr} | grep -c 'ERROR')"
    exit_status="$(cat ${artifactcheck_exit})"
    if [[ "${status1}" -gt 0 ]] || [[ "${status2}" -gt 0 ]] || [[ "${exit_status}" -ne 0 ]]
    then
        artifactcheck_status=1
    fi
    if [[ ! -f "${artifactcheck_cmd}" ]] || [[ "${pkg_check}" == "FALSE" ]]
    then
        artifactcheck_status=2
    fi

    # Test log
    status1="$(cat ${test_log} | grep -c 'Error: Test failures')"
    status2="$(cat ${test_log} | grep -c 'Execution halted')"
    status3="$(cat ${test_log} | grep -c 'Error: No tests found')"
    if [[ "${status1}" -gt 0 ]] || [[ "${status2}" -gt 0 ]]
    then
        test_status=1
    fi
    if [[ ! -f "${test_log}" ]] || [[ "${status3}" -gt 0 ]] || [[ "${pkg_test}" == "FALSE" ]]
    then
        test_status=2
    fi
    if [[ "${pkg_test}" == "FALSE" ]]
    then
        echo "${pkg_test} ${pkg_name} ${test_status}"
    fi

    echo "${pkg_name},${pkg_version},${pkg_source},${download_status},${build_status},${check_status},${install_status},${artifact_status},${artifactcheck_status},${test_status}" >> "${status_csv}"
done < "${input_csv}"

