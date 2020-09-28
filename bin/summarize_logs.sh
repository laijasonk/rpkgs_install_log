#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv [-o summary.csv] [-c config]"
    echo "Flags:"
    echo "       -i path to input csv file"
    echo "       -o OPTIONAL path to output summary csv"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "i:o:c:h" opt
do
    case $opt in
        i)
            input_csv="$(readlink -f ${OPTARG})"
            ;;
        o)
            summary_csv="$(redlink -f ${OPTARG})"
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
if [[ -z "${input_csv}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"

# Point to correct output file and reset
if [[ -z "${status_csv}" ]]
then
    status_csv="${log_dir}/_summary.csv"
fi
cat /dev/null > "${status_csv}"

# Loop through input csv file
while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check
do
    wget_log="${log_dir}/wget_${pkg_name}.txt"
    build_log="${log_dir}/build_${pkg_name}.txt"
    install_log="${log_dir}/install_${pkg_name}.txt"
    check_log="${log_dir}/check_${pkg_name}.txt"
    artifact_log="${log_dir}/artifact_${pkg_name}.txt"
    artifactcheck_log="${log_dir}/artifactcheck_${pkg_name}.txt"
    test_log="${log_dir}/test_${pkg_name}.txt"

    wget_status=0
    build_status=0
    install_status=0
    check_status=0
    artifact_status=0
    artifactcheck_status=0
    test_status=0

    # Download log
    status1="$(cat ${wget_log} | grep -c 'ERROR 404')"
    if [[ "${status1}" -gt 0 ]]
    then
        wget_status=1
    fi
    if [[ ! -f "${wget_log}" ]]
    then
        wget_status=2
    fi

    # Build log
    status1="$(cat ${build_log} | grep -c 'ERROR')"
    if [[ "${status1}" -gt 0 ]]
    then
        build_status=1
    fi
    if [[ ! -f "${build_log}" ]]
    then
        build_status=2
    fi
    
    # Install log
    status1="$(cat ${install_log} | grep -c 'ERROR')"
    if [[ "${status1}" -gt 0 ]]
    then
        install_status=1
    fi
    if [[ ! -f "${install_log}" ]]
    then
        install_status=2
    fi
    
    # Check log
    status1="$(cat ${check_log} | grep -c 'neither a file nor directory')"
    status2="$(cat ${check_log} | grep -c 'ERROR')"
    if [[ "${status1}" -gt 0 ]] || [[ "${status2}" -gt 0 ]]
    then
        check_status=1
    fi
    if [[ ! -f "${check_log}" ]] || [[ "${pkg_check}" == "FALSE" ]]
    then
        check_status=2
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
    status1="$(cat ${artifactcheck_log} | grep -c 'neither a file nor directory')"
    status2="$(cat ${artifactcheck_log} | grep -c 'ERROR')"
    if [[ "${status1}" -gt 0 ]] || [[ "${status2}" -gt 0 ]]
    then
        artifactcheck_status=1
    fi
    if [[ ! -f "${artifactcheck_log}" ]] || [[ "${pkg_check}" == "FALSE" ]]
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
    if [[ ! -f "${test_log}" ]] || [[ "${status3}" -gt 0 ]]
    then
        test_status=2
    fi

    echo "${pkg_name},${pkg_version},${pkg_source},${wget_status},${build_status},${install_status},${check_status},${artifact_status},${artifactcheck_status},${test_status}" >> "${status_csv}"
done < "${input_csv}"

