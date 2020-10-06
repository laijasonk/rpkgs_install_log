#!/usr/bin/env bash
#
# Download and build source packages
# 

# Default values
curr_dir=$(pwd)

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
    echo "       -t OPTIONAL path to target directory"
}

# Argument flag handling
while getopts "n:v:s:o:p:b:h:t:" opt
do
    case $opt in
        n) pkg_name="${OPTARG}" ;;
        v) pkg_version="${OPTARG}" ;;
        s) pkg_source="${OPTARG}" ;;
        o) pkg_org="${OPTARG}" ;;
        p) pkg_project="${OPTARG}" ;;
        b) pkg_branch="${OPTARG}" ;;
        h) pkg_hash="${OPTARG}" ;;
        t) target_dir="${OPTARG}" ;;
        *) usage ;;
    esac
done

# Conditions to run script
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

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Define log files
missing_dep_log="${log_dir}/_missing_dependencies.txt"
cat /dev/null > "${missing_dep_log}"
build_cmd="${log_dir}/build_${pkg_name}_cmd.txt"
build_stdout="${log_dir}/build_${pkg_name}_stdout.txt"
build_stderr="${log_dir}/build_${pkg_name}_stderr.txt"
build_exit="${log_dir}/build_${pkg_name}_exit.txt"
pkg_download="${log_dir}/download_${pkg_name}.txt"
pkg_extract="${log_dir}/extract_${pkg_name}.txt"

# Download instructions for different sources
if [[ "${pkg_source}" == "cran" ]]
then
    
    # Define variables
    ext="tar.gz"
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 
    pkg_url_1="https://cran.r-project.org/src/contrib/${pkg_name}_${pkg_version}.tar.gz"
    pkg_url_2="https://cran.r-project.org/src/contrib/Archive/${pkg_name}/${pkg_name}_${pkg_version}.tar.gz"
    pkg_build="${src_dir}/${pkg_name}"

    echo "Searching for valid '${pkg_name}' URL to download"
    if [[ "$(curl --write-out '%{http_code}' --silent --output /dev/null ${pkg_url_1} | grep -c '200')" -ge 1 ]]
    then
        echo "Downloading '${pkg_name}' (latest) to '${src_dir}'"
        curl -o "${pkg_archive}" "${pkg_url_1}" &> "${pkg_download}"
    elif [[ "$(curl --write-out '%{http_code}' --silent --output /dev/null ${pkg_url_2} | grep -c '200')" -ge 1 ]]
    then
        echo "Downloading '${pkg_name}' (archive) to '${src_dir}'"
        curl -o "${pkg_archive}" "${pkg_url_2}" &> "${pkg_download}"
    else
        echo "Could not download '${pkg_name}' (see log)"
        echo "Could not download from '${pkg_url_1}' or '${pkg_url_2}'" &> "${pkg_download}"
    fi

    echo "Extracting '${pkg_name}' to '${src_dir}'"
    tar xvf "${pkg_archive}" --directory "${src_dir}" &> "${pkg_extract}"

elif [[ "${pkg_source}" == "github" ]]
then

    # Define variables
    ext="zip"
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 

    if [[ ! -z "${pkg_hash}" ]]
    then
        pkg_url="https://codeload.github.com/${pkg_org}/${pkg_project}/zip/${pkg_hash}"
        pkg_build="${src_dir}/${pkg_name}-${pkg_hash}"
    elif [[ ! -z "${pkg_branch}" ]]
    then
        pkg_url="https://codeload.github.com/${pkg_org}/${pkg_project}/zip/${pkg_branch}"
        pkg_branch_clean="$(echo ${pkg_branch} | sed 's/\//-/g')"
        pkg_build="${src_dir}/${pkg_name}-${pkg_branch_clean}"
    else
        echo "Could not download '${pkg_name}'"
        echo "Could not download because neither commit hash nor branch name have been specified" &> "${pkg_download}"
    fi

    echo "Downloading '${pkg_name}' to '${src_dir}'"
    curl -o "${pkg_archive}" "${pkg_url}" &> "${pkg_download}"

    echo "Extracting '${pkg_name}' to '${src_dir}'"
    unzip -o "${pkg_archive}" -d "${src_dir}" &> "${pkg_extract}"

elif [[ "${pkg_source}" == "nest" ]]
then
    # TODO
    :
fi
 
echo "Building '${pkg_name}' from '${src_dir}'"
cd "${src_dir}"
cmd="${rbinary} CMD build --no-build-vignettes \"${pkg_build}\""
echo "${cmd}" > "${build_cmd}"
eval -- "${cmd}" 2> "${build_stderr}" 1> "${build_stdout}"
echo $? > "${build_exit}"
tarball="$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
cd "${curr_dir}"
   
echo "Moving build tarball to '${build_dir}'"
src_tarball="${src_dir}/${tarball}"
build_tarball="${build_dir}/${tarball}"
if [[ -f "${src_tarball}" ]]
then
    mv "${src_tarball}" "${build_tarball}"
else
    echo "WARNING: Build tarball does not exist; build probably failed"
fi

