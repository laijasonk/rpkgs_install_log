#!/usr/bin/env bash
#
# Download and install source packages
# 

# Default values
curr_dir=$(pwd)
download_from_cran=false
artifactory=false

# Help message
function usage {
    echo "Usage: $0 -i pkg_archive"
    echo "       $0 -i pkg_archive [-a]"
    echo "       $0 -i pkg_archive [-m]"
    echo "       $0 -i pkg_archive [-t $(pwd)]"
    echo "Flags:"
    echo "       -i path to source tarball"
    echo "       -a OPTIONAL artifactory install"
    echo "       -m OPTIONAL install missing dependencies from CRAN"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:amt:h" opt
do
    case $opt in
        i) pkg_archive="$(readlink -f ${OPTARG})" ;;
        a) artifactory=true ;;
        m) download_from_cran=true ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${pkg_archive}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Define log files
missing_dep_log="${log_dir}/_missing_dependencies.txt"
cat /dev/null > "${missing_dep_log}"

# Function for installing package
function install_package() {
    
    # Function input arguments
    pkg_name="${1}"
    pkg_archive="${2}"

    # Define log file
    if [ ${artifactory} = true ]
    then
        install_log="${log_dir}/artifactinstall_${pkg_name}.txt"
    else
        install_log="${log_dir}/install_${pkg_name}.txt"
    fi

    # Install package
    cmd="${rbinary} CMD INSTALL --install-tests --library=${lib_dir} \"${pkg_archive}\"" 
    echo -e "CMD: ${cmd}\n----------\n\n" > "${install_log}"
    eval -- "${cmd}" >> "${install_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${install_log}"

    # Install dependencies if missing
    missing_dependency=$(grep 'ERROR: dependenc' "${install_log}")
    if [[ "${missing_dependency}" ]]
    then
        # Text manipulation to extract substring dependency from error line
        dependency=$(echo "${missing_dependency}" | awk '{print($3)}' | sed -e 's/[^A-Za-z0-9\.]//g')

        # Report missing dependency
        echo "Package required missing dependency '${dependency}'"
        echo -n "'${tarball}' required missing dependency: ${dependency}" >> "${missing_dep_log}"

        # Install package from external repo if option is set
        if [ ${download_from_cran} = true ]
        then
            depinstall_log="${log_dir}/depinstall_${dependency}.txt"

            echo "Installing missing dependency '${dependency}' to '${lib_dir}'"
            cmd="${rscript} -e \"install.packages('${dependency}', repos='${external_repo}', lib='${lib_dir}')\""
            eval -- "${cmd}" &> "${depinstall_log}"
        else
            # Reset and ignore after logging the issue above
            missing_dependency=''
        fi
    fi
}

pkg_name="$(basename ${pkg_archive} | sed 's/_.*$//')"

# Reset for new package
missing_dependency=''

# Call BASH function to install package
echo "Installing '${pkg_name}' to '${lib_dir}'"
install_package "${pkg_name}" "${pkg_archive}"

# Repeat when missing dependencies
while [[ "${missing_dependency}" ]]
do
    echo "Resolved dependency. Installing '${pkg_name}' to '${lib_dir}'"
    install_package "${pkg_name}" "${pkg_archive}"
done

