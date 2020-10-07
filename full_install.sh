#!/usr/bin/env bash
#
# Run full pipeline
#

# Default values
wait_between_packages=false
disable_checks=true
disable_tests=true
in_rlibs=$(Rscript -e "cat(paste(.libPaths(), collapse=':'))")
in_rbinary="$(which R)"
in_rscript="$(which Rscript)"
target_dir="$(pwd)"
cmd="${0}"

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv [-l ${in_rlibs}]"
    echo "       $0 -i input.csv [-b ${in_rbinary}] [-s ${in_rscript}]"
    echo "       $0 -i input.csv [-c] [-u]"
    echo "       $0 -i input.csv [-t ${target_dir}]"
    echo "Flags:"
    echo "       -i input csv containing release packages"
    echo "       -l OPTIONAL libpaths to build on (separated by colon on GNU/Linux)"
    echo "       -b OPTIONAL path to R binary"
    echo "       -s OPTIONAL path to Rscript executable"
    echo "       -c OPTIONAL enable and run checks (disabled by default)"
    echo "       -u OPTIONAL enable and run unit tests (disabled by default)"
    echo "       -t OPTIONAL target directory (default: current directory)"
    exit 1
}

# Argument flag handling
while getopts "i:l:b:s:cut:h" opt
do
    case $opt in
        i) 
            input_csv="$(readlink -f ${OPTARG})" 
            cmd="${cmd} -i ${OPTARG}" ;;
        l) 
            in_rlibs="${OPTARG}"
            cmd="${cmd} -l ${OPTARG}" ;;
        b) 
            in_rbinary="$(readlink -f ${OPTARG})"
            cmd="${cmd} -b ${OPTARG}" ;;
        s) 
            in_rscript="$(readlink -f ${OPTARG})"
            cmd="${cmd} -s ${OPTARG}" ;;
        c)
            disable_checks=false
            cmd="${cmd} -c" ;;
        u)
            disable_tests=false
            cmd="${cmd} -u" ;;
        t) 
            mkdir -p "${OPTARG}"
            target_dir="$(readlink -f ${OPTARG})"
            cmd="${cmd} -t ${OPTARG}" ;;
        h) 
            usage ;;
        *) 
            usage ;;
    esac
done

# Conditions for running script
if [[ -z "${input_csv}" ]] || [[ ! -f "${input_csv}" ]]
then
    usage
fi
if [[ -z "${target_dir}" ]]
then
    usage
fi

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

# Variables
. ./bin/global_config.sh -t "${target_dir}"
echo "${in_rlibs}" > "${log_dir}"/_rlibs.txt
echo "${in_rbinary}" > "${log_dir}"/_rbinary.txt
echo "${in_rscript}" > "${log_dir}"/_rscript.txt
. ./bin/global_config.sh -t "${target_dir}"
echo "CMD: ${cmd}" > ./_stdout.txt
echo >> ./_stdout.txt

# Prepare system
header_msg "Initializing system" | tee -a ./_stdout.txt

# Set the default variables and reset install
./bin/reset_install.sh -t "${target_dir}" | tee -a ./_stdout.txt

# Store stdout into the log directory
stdout_log="${log_dir}/_stdout.txt"
mv ./_stdout.txt "${stdout_log}"

pkg_csv="${log_dir}/_input.csv"
./bin/strip_csv.sh \
    -1 \
    -i "${input_csv}" \
    -o "${pkg_csv}" | tee -a "${stdout_log}"

./bin/export_installed_packages.sh -1 -t "${target_dir}" | tee -a "${stdout_log}"
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
        -u "${pkg_url}" \
        -c "${git_commit}" \
        -t "${target_dir}" | tee -a "${stdout_log}"

    ./bin/install_source_package.sh \
        -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
        -t "${target_dir}" | tee -a "${stdout_log}"

    #if [[ "${pkg_check}" == "TRUE" ]]
    if [ ${disable_checks} = false ]
    then
        ./bin/check_source_package.sh \
            -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
            -t "${target_dir}" | tee -a "${stdout_log}"
    else
        echo "Check skipped due to input CSV specification for '${pkg_name}'" > "${log_dir}/check_${pkg_name}.txt"
    fi
    
    #if [[ "${pkg_test}" == "TRUE" ]]
    if [ ${disable_tests} = false ]
    then
        ./bin/test_installed_package.sh \
            -i "${pkg_name}" \
            -t "${target_dir}" | tee -a "${stdout_log}"
    else
        echo "Test skipped due to input CSV specification for '${pkg_name}'" > "${log_dir}/test_${pkg_name}.txt"
    fi

    echo

done < "${pkg_csv}"

header_msg "Post-installation" | tee -a "${stdout_log}"
./bin/export_installed_packages.sh -2 -t "${target_dir}" | tee -a "${stdout_log}"
echo "Saving end timestamp" | tee -a "${stdout_log}"
echo "$(date)" > "${log_dir}/_end_timestamp.txt" | tee -a "${stdout_log}"
echo | tee -a "${stdout_log}"

header_msg "Creating HTML log" | tee -a "${stdout_log}"
./bin/summarize_logs.sh -i "${pkg_csv}" -t "${target_dir}" &> /dev/null
./bin/generate_html.sh -t "${target_dir}" | tee -a "${stdout_log}"

