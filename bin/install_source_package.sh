#!/usr/bin/env bash
#
# Download and install source packages
# 

curr_dir=$(pwd)

# Default values
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log/raw)"
external_repo="http://cran.r-project.org"
download_from_cran=false

# Help message
function usage {
    echo "Usage: $0 -i pkg_archive"
    echo "       $0 -i pkg_archive [-r /path/to/libs-r]"
    echo "       $0 -i pkg_archive [-m] [-d /path/to/libs-cran]"
    echo "Flags:"
    echo "       -i path to source tarball"
    echo "       -r OPTIONAL lib path to the local R (default: ${lib_dir})"
    echo "       -m OPTIONAL install missing dependencies from CRAN"
    echo "       -d OPTIONAL lib path for missing dep (default: ${cran_dir})" 
    exit 1
}

# Argument flag handling
while getopts "i:mr:d:" opt
do
    case $opt in
        i)
            pkg_archive="${OPTARG}"
            ;;
        r)
            lib_dir="${OPTARG}"
            ;;
        m)
            download_from_cran=true
            ;;
        d)
            cran_dir="${OPTARG}"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Package archive must be provided
if [[ -z "${pkg_archive}" ]]
then
    usage
fi

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${src_dir}" "${build_dir}" "${log_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Define log files
missing_dep_log="${log_dir}/_missing_dependencies.txt"
build_archives_log="${log_dir}/_build_archives.txt"
cat /dev/null > "${missing_dep_log}"
cat /dev/null > "${build_archives_log}"

# Function for installing package
function install_package() {
    
    # Function input arguments
    pkg_name="${1}"
    pkg_archive="${2}"

    # Define log file
    install_log="${log_dir}/install_${pkg_name}.txt"

    # Install package
    R CMD INSTALL \
        --install-tests \
        --build \
        -l "${lib_dir}" \
        "${pkg_archive}" &> "${install_log}"

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

            echo "Installing dependency '${dependency}' from CRAN to '${cran_dir}'"
            Rscript -e "install.packages(\"${dependency}\", repos=\"${external_repo}\", lib=\"${cran_dir}\")" &> "${depinstall_log}"
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

# Move installed build archives to build directory
echo "Moving build tarball to '${build_dir}'"
build_archive="$(cat ${install_log} | grep 'packaged installation of' | sed -e 's/^.*’ as ‘//' -e 's/’.*$//')"
if [[ -f "./${build_archive}" ]]
then
    mv "./${build_archive}" "${build_dir}"
else
    echo "WARNING: Build tarball does not exist; build probably failed"
fi
echo "${build_archive}" >> "${build_archives_log}"
echo 

