#!/usr/bin/env bash
#
# Inspect artifactory
#

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv [-t $(pwd)]"
    echo "Flags:"
    echo "       -i path to input csv"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:t:h" opt
do
    case $opt in
        i) input_csv="$(readlink -f ${OPTARG})" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check pkg_test
do
    # Status of the file
    artifact_file="${build_dir}/${pkg_name}_${pkg_version}.tar.gz"
    artifact_log="${log_dir}/artifact_${pkg_name}.txt"
    if [[ ! -f "${artifact_file}" ]]
    then
        echo "Missing file" > "${artifact_log}"
    else
        echo "Build tarball for '${pkg_name}' found." > "${artifact_log}"
        echo "    Path: ${artifact_file}" >> "${artifact_log}"
    fi

    # Copy artifact check file
    artifact_check_log="${build_check_dir}/${pkg_name}.txt"
    new_artifact_check_log="${log_dir}/artifactcheck_${pkg_name}.txt"
    if [[ "${pkg_check}" == "FALSE" ]]
    then
        echo "validnest_steps check = FALSE" > "${new_artifact_check_log}"
    else
        if [[ ! -f "${artifact_check_log}" ]]
        then
            echo "Missing file" > "${new_artifact_check_log}"
        else
            cp "${artifact_check_log}" "${new_artifact_check_log}"
        fi
    fi
done < "${input_csv}"

