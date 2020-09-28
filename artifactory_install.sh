#!/usr/bin/env bash
#
# Run full pipeline
#

# Default values
wait_between_packages=false

# Help message
function usage {
    echo "Usage: $0 -y input.yaml"
    echo "       $0 -y input.yaml [-w] [-c config]"
    echo "Flags:"
    echo "       -y input yaml containing release packages"
    echo "       -w OPTIONAL stop between each package and wait for user"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "y:wc:h" opt
do
    case $opt in
        y)
            input_yaml="$(readlink -fq ${OPTARG})"
            ;;
        w)
            wait_between_commands=true
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

# Input CSV must be provided
if [[ -z "${input_yaml}" ]] || [[ ! -f "${input_yaml}" ]]
then
    usage
fi

# Variables
. ./bin/read_config.sh -c "${config_file}"
input_csv="$(readlink -f ${log_dir}/_input.csv)"

# Basic message display between each package
function header_msg() {
    echo
    echo "##################################################"
    echo "#"
    echo "# ${1}"
    echo "#"
    echo "##################################################"
    echo
    
    if [ ${wait_between_packages} = true ]
    then
        read -p "" null
    else
        echo
    fi
}

# Prepare system (commend out if unneeded
header_msg "Initializing system"

./bin/yaml_to_csv.sh \
    -i "${input_yaml}" \
    -o "${input_csv}" \
    -c "${config_file}"

./bin/inspect_artifactory.sh \
    -i "${input_csv}" \
    -c ${config_file}

./bin/export_installed_packages.sh -1 -c "${config_file}"
echo "$(date)" > "${log_dir}/_start_timestamp.txt"
echo

# Build, install, check, and test every package
while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check
do
    header_msg "${pkg_name}-${pkg_version}"

    ./bin/install_source_package.sh \
        -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
        -c "${config_file}"

    ./bin/test_installed_package.sh \
        -i "${pkg_name}" \
        -c "${config_file}"
done < "${input_csv}"

# Log end timestamp and state
./bin/export_installed_packages.sh -2 -c "${config_file}"
echo "$(date)" > "${log_dir}/_end_timestamp.txt"

header_msg "Creating HTML log"
./bin/summarize_logs.sh -i "${input_csv}" -c "${config_file}"
./bin/generate_html.sh -3 -c "${config_file}"

