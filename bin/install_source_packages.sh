#!/usr/bin/env bash
#
# Download and install source packages
# 

curr_dir=$(pwd)

# Default values (TODO: make these option flags)
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log)"
external_repo="http://cran.r-project.org"
download_from_cran=false

# Help message
function usage {
    echo "Usage: $0 -i ./input.csv"
    echo "       $0 -i ./input.csv [-r /path/to/libs-r]"
    echo "       $0 -i ./input.csv [-m] [-d /path/to/libs-cran]"
    echo "Flags:"
    echo "       -i input CSV containing a package on each newline"
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
            input_csv="${OPTARG}"
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
        :)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Input CSV must be provided
if [[ -z "${input_csv}" ]]
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
missing_dep_log="${log_dir}/_missing_dependencies.log"
downloaded_packages="${log_dir}/_downloaded_packages.log"
cat /dev/null > "${missing_dep_log}"
cat /dev/null > "${downloaded_packages}"

# Function for installing package
function install_package() {
    
    # Function input arguments
    pkg_name="${1}"
    pkg_archive="${2}"

    # Define log file
    install_log="${log_dir}/install_${pkg_name}.log"

    # Install package
    R CMD INSTALL \
        --install-tests \
        --build \
        -l "${lib_dir}" \
        "${pkg_archive}" &> "${install_log}"

    # Install dependencies if missing
    missing_dependency=$(grep 'ERROR: dependency' "${install_log}")
    if [[ "${missing_dependency}" ]]
    then
        # Text manipulation to extract substring dependency from error line
        dependency=$(echo "${missing_dependency}" | awk '{print($3)}' | sed -e 's/[^A-Za-z0-9\.]//g')

        # Report missing dependency
        echo "Package required missing dependency ${dependency}"
        echo -n "${tarball} required missing dependency: ${dependency}" >> "${missing_dep_log}"

        # Install package from external repo if option is set
        if [ ${download_from_cran} = true ]
        then
            depinstall_log="${log_dir}/depinstall_${dependency}.log"

            echo "Installing dependency ${dependency} from CRAN to ${cran_dir}"
            Rscript -e "install.packages(\"${dependency}\", repos=\"${external_repo}\", lib=\"${cran_dir}\")" &> "${depinstall_log}"
        else
            # Reset and ignore after logging the issue above
            missing_dependency=''
        fi
    fi
}

# Loop through every line of input CSV file
while IFS=, read -r pkg_name pkg_version pkg_type pkg_url
do
    
    if [[ "${pkg_type}" == "release" ]]
    then
        
        # Check the extension
        if [[ "${pkg_url:(-7)}" == ".tar.gz" ]]
        then
            ext="tar.gz"
        elif [[ "${pkg_url:(-8)}" == ".tar.bz2" ]]
        then
            ext="tar.bz2"
        else
            ext="${pkg_url##*.}"
        fi

        # Define variables
        pkg_archive="${src_dir}/${pkg_name}-${pkg_version}.${ext}" 
        pkg_wget="${log_dir}/wget_${pkg_name}-${pkg_version}.log"
        missing_dependency=''

        # Use wget to download package
        echo "Downloading ${pkg_name} to ${src_dir}"
        wget --continue -O "${pkg_archive}" "${pkg_url}" &> "${pkg_wget}"
        echo "${pkg_archive}" >> "${downloaded_packages}"

    elif [[ "${pkg_type}" == "source" ]]
    then

        echo "Building ${pkg_name} from ${pkg_url}"
        build_log="${log_dir}/build_${pkg_name}.log"

        cd "$(dirname ${pkg_url})"
        R CMD build "$(basename ${pkg_url})" &> "${build_log}"
        pkg_archive="${src_dir}/$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
        cd ${curr_dir}

    fi

    # Call BASH function to install package
    echo "Installing ${pkg_name} to ${lib_dir}"
    install_package "${pkg_name}" "${pkg_archive}"

    # Repeat when missing dependencies
    while [[ "${missing_dependency}" ]]
    do
        echo "Resolved dependency. Installing ${pkg_name} to ${lib_dir}"
        install_package "${pkg_name}" "${pkg_archive}"
    done

    echo

done < "${input_csv}"

# Move installed build archives to build directory
echo "Moving build files to ${build_dir}"
mv "${curr_dir}"/*.tar.gz "${build_dir}"/
echo

