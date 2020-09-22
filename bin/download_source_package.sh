#!/usr/bin/env bash
#
# Download source packages
# 

curr_dir=$(pwd)

# Default values
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
log_dir="$(readlink -f ./log/raw)"
download_from_cran=false

# Help message
function usage {
    echo "Usage: $0 -n name -v version -s 'cran'"
    echo "       $0 -n name -v version -s 'github' -o org -p project -b branch"
    echo "       $0 -n name -v version -s 'github' -o org -p project -h sha_hash"
    echo "Flags:"
    echo "       -n package name"
    echo "       -v package version number"
    echo "       -s source (currently supported: 'cran' or 'github')"
    echo "       -o github organization"
    echo "       -p github project repository name"
    echo "       -b github branch name"
    echo "       -h github SHA hash"
    exit 1
}

# Argument flag handling
while getopts "n:v:s:o:p:b:h:" opt
do
    case $opt in
        n)
            pkg_name="${OPTARG}"
            ;;
        v)
            pkg_version="${OPTARG}"
            ;;
        s)
            pkg_source="${OPTARG}"
            ;;
        o)
            pkg_org="${OPTARG}"
            ;;
        p)
            pkg_project="${OPTARG}"
            ;;
        b)
            pkg_branch="${OPTARG}"
            ;;
        h)
            pkg_hash="${OPTARG}"
            ;;
        :)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Conditions to run
if [[ -z "${pkg_name}" ]] || [[ -z "${pkg_version}" ]] || [[ -z "${pkg_source}" ]]
then
    usage
elif [[ "${pkg_source}" == "cran" ]]
then
    :
elif [[ "${pkg_source}" == "github" ]]
then
    if [[ -z "${pkg_org}" ]] || [[ -z "${pkg_project}" ]]
    then
        usage
    elif [[ -z "${pkg_branch}" ]] && [[ -z "${pkg_hash}" ]]
    then
        usage
    else
        :
    fi
fi

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${src_dir}" "${log_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Define log files
missing_dep_log="${log_dir}/_missing_dependencies.text"
pkg_archive_log="${log_dir}/_package_archives.txt"
cat /dev/null > "${missing_dep_log}"
cat /dev/null > "${pkg_archive_log}"

# Download instructions for different sources
if [[ "${pkg_source}" == "cran" ]]
then
    
    # Define variables
    ext="tar.gz"
    pkg_archive="${src_dir}/cran/${pkg_name}_${pkg_version}.${ext}" 
    pkg_wget="${log_dir}/wget_${pkg_name}.txt"
    pkg_extract="${log_dir}/extract_${pkg_name}.txt"
    build_log="${log_dir}/build_${pkg_name}.txt"
    pkg_url_1="https://cran.r-project.org/src/contrib/${pkg_name}_${pkg_version}.tar.gz"
    pkg_url_2="https://cran.r-project.org/src/contrib/Archive/${pkg_name}/${pkg_name}_${pkg_version}.tar.gz"
    pkg_build="${src_dir}/cran/${pkg_name}"

    echo "Checking '${pkg_name}' URL for download"
    if [[ $(wget -S --spider "${pkg_url_1}" 2>&1 | grep 'HTTP/1.1 200 OK') ]]
    then
        echo "Downloading '${pkg_name}' (latest) to '${src_dir}/cran'"
        wget --continue -O "${pkg_archive}" "${pkg_url_1}" &> "${pkg_wget}"
    elif [[ $(wget -S --spider "${pkg_url_2}" 2>&1 | grep 'HTTP/1.1 200 OK') ]]
    then
        echo "Downloading '${pkg_name}' (archive) to '${src_dir}/cran'"
        wget --continue -O "${pkg_archive}" "${pkg_url_1}" &> "${pkg_wget}"
    else
        echo "Could not download '${pkg_name}' (see log)"
        echo "Could not download from '${pkg_url_1}' or '${pkg_url_2}'" &> "${pkg_wget}"
    fi

    echo "Extracting '${pkg_name}' to '${src_dir}/cran'"
    tar xvf "${pkg_archive}" --directory "${src_dir}"/cran/ &> "${pkg_extract}"

    echo "Building '${pkg_name}' from '${src_dir}'"
    cd ${src_dir}
    R CMD build --no-build-vignettes "${pkg_build}" &> "${build_log}"
    cd ${curr_dir}
    pkg_tarball="${src_dir}/$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"

elif [[ "${pkg_source}" == "github" ]]
then

    # Define variables
    ext="zip"
    pkg_archive="${src_dir}/github/${pkg_name}_${pkg_version}.${ext}" 
    pkg_wget="${log_dir}/wget_${pkg_name}.txt"
    pkg_extract="${log_dir}/extract_${pkg_name}.txt"
    build_log="${log_dir}/build_${pkg_name}.txt"

    if [[ ! -z "${pkg_hash}" ]]
    then
        pkg_url="https://github.com/${pkg_org}/${pkg_project}/archive/${pkg_hash}.zip"
        pkg_build="${src_dir}/github/${pkg_name}-${pkg_hash}"
    elif [[ ! -z "{$pkg_branch}" ]]
    then
        pkg_url="https://github.com/${pkg_org}/${pkg_project}/archive/${pkg_branch}.zip"
        pkg_branch_clean="$(echo ${pkg_branch} | sed 's/\//-/g')"
        pkg_build="${src_dir}/github/${pkg_name}-${pkg_branch_clean}"
    fi

    echo "Downloading '${pkg_name}' to '${src_dir}/github'"
    wget --continue -O "${pkg_archive}" "${pkg_url}" &> "${pkg_wget}"

    echo "Extracting '${pkg_name}' to '${src_dir}/github'"
    unzip -o "${pkg_archive}" -d "${src_dir}"/github/ &> "${pkg_extract}"

    echo "Building '${pkg_name}' from '${src_dir}'"
    cd ${src_dir}
    R CMD build "${pkg_build}" &> "${build_log}"
    cd ${curr_dir}
    pkg_tarball="${src_dir}/$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"

fi
    
echo "${pkg_tarball}" >> "${pkg_archive_log}"
echo

