#!/usr/bin/env bash
#
# Run full pipeline
#

# Default values
wait_between_packages=false

# Help message
function usage {
    echo "Usage: $0 -i input.csv -c config"
    echo "       $0 -i input.csv -c config [-w]"
    echo "Flags:"
    echo "       -i input yaml containing release packages"
    echo "       -c path to config file"
    echo "       -w OPTIONAL stop between each package and wait for user"
    exit 1
}

# Argument flag handling
while getopts "i:c:wh" opt
do
    case $opt in
        i)
            input_csv="$(readlink -fq ${OPTARG})"
            ;;
        c)
            config_file="${OPTARG}"
            ;;
        w)
            wait_between_commands=true
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
if [[ -z "${input_csv}" ]] || [[ ! -f "${input_csv}" ]]
then
    usage
fi

# Variables
. ./bin/read_config.sh -c "${config_file}"
stdout_log="${log_dir}/_stdout.txt"

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
header_msg "Initializing system" | tee ./stdout.txt

./bin/reset_install.sh -c "${config_file}" | tee -a ./stdout.txt
mv ./stdout.txt "${stdout_log}"
. ./bin/read_config.sh -c "${config_file}" | tee -a "${stdout_log}"

pkg_csv="$(readlink -f ${log_dir}/_input.csv)" | tee -a "${stdout_log}"
./bin/strip_csv.sh -1 -i "${input_csv}" -o "${pkg_csv}" | tee -a "${stdout_log}"

./bin/export_installed_packages.sh -1 -c "${config_file}" | tee -a "${stdout_log}"
echo "Saving start timestamp" | tee -a "${stdout_log}"
echo "$(date)" > "${log_dir}/_start_timestamp.txt" | tee -a "${stdout_log}"
echo | tee -a "${stdout_log}"

# Build, install, check, and test every package
while IFS=, read -r pkg_name pkg_version pkg_url pkg_source git_commit
do

    header_msg "${pkg_name}-${pkg_version}" | tee -a "${stdout_log}"

    ./bin/download_and_build.sh \
        -n "${pkg_name}" \
        -v "${pkg_version}" \
        -s "${pkg_source}" \
        -o "${pkg_org}" \
        -p "${pkg_repo}" \
        -b "${pkg_branch}" \
        -h "${pkg_hash}" \
        -c "${config_file}" | tee -a "${stdout_log}"

    ./bin/install_source_package.sh \
        -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
        -c "${config_file}" | tee -a "${stdout_log}"

    if [[ "${pkg_check}" == "TRUE" ]]
    then
        ./bin/check_source_package.sh \
            -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
            -c "${config_file}" | tee -a "${stdout_log}"
    else
        echo "validnest_steps check = FALSE" > "${log_dir}/check_${pkg_name}.txt"
    fi

    echo

done < "${pkg_csv}"

header_msg "Post-build" | tee -a "${stdout_log}"
./bin/export_installed_packages.sh -2 -c "${config_file}" | tee -a "${stdout_log}"
echo "Saving end timestamp" | tee -a "${stdout_log}"
echo "$(date)" > "${log_dir}/_end_timestamp.txt" | tee -a "${stdout_log}"
echo | tee -a "${stdout_log}"

header_msg "Creating HTML log" | tee -a "${stdout_log}"
./bin/summarize_logs.sh -i "${pkg_csv}" -c "${config_file}" &> /dev/null
./bin/generate_html.sh -2 -c "${config_file}" | tee -a "${stdout_log}"

