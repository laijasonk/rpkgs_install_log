#!/usr/bin/env bash
#
# Download and build source packages
# 
# Default values
curr_dir=$(pwd)

# Help message
function usage {
    echo "Usage: $0 -n name -v version -u http://buildurl -s 'buildfile'"
    echo "       $0 -n name -v version -u http://giturl -s 'git' -c commit_hash"
    echo "       $0 -n name -v version -u /path/to/url -s 'local'"
    echo "Flags:"
    echo "       -n package name"
    echo "       -v package version number"
    echo "       -u file url (if source=buildfile or git) or path to tarball (if source=local)"
    echo "       -s source (currently supported: 'buildfile' or 'git' or 'local')"
    echo "       -h github commit SHA hash"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "n:v:s:u:c:t:h" opt
do
    case $opt in
        n) pkg_name="${OPTARG}" ;;
        v) pkg_version="${OPTARG}" ;;
        u) pkg_url="${OPTARG}" ;;
        s) pkg_source="${OPTARG}" ;;
        c) git_commit="${OPTARG}" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${pkg_name}" ]] || [[ -z "${pkg_version}" ]] || [[ -z "${pkg_source}" ]] || [[ -z "${pkg_url}" ]]
then
    echo 'hit 1'
    usage
elif [[ "${pkg_source}" == "buildfile" ]]
then
    :
elif [[ "${pkg_source}" == "git" ]] && [[ ! -z "${git_commit}" ]] 
then
    :
elif [[ "${pkg_source}" == "local" ]]
then
    :
else
    echo 'hit 2'
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Define log files
missing_dep_log="${log_dir}/_missing_dependencies.txt"
cat /dev/null > "${missing_dep_log}"

# Download instructions for different sources
if [[ "${pkg_source}" == "buildfile" ]]
then
    
    # Define variables
    ext="tar.gz"
    pkg_archive="${build_dir}/${pkg_name}_${pkg_version}.${ext}" 
    pkg_download="${log_dir}/download_${pkg_name}.txt"
    pkg_build="${src_dir}/${pkg_name}"

    echo "Downloading '${pkg_name}' to '${src_dir}'"
    wget --continue -O "${pkg_archive}" "${pkg_url}" &> "${pkg_download}"

elif [[ "${pkg_source}" == "git" ]]
then

    # Define variables
    ext="zip"
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 
    pkg_download="${log_dir}/download_${pkg_name}.txt"
    pkg_extract="${log_dir}/extract_${pkg_name}.txt"
    build_log="${log_dir}/build_${pkg_name}.txt"

    if [[ ! -z "${git_commit}" ]]
    then
        pkg_url="https://github.com/${pkg_org}/${pkg_project}/archive/${git_commit}.zip"
        pkg_build="${src_dir}/${pkg_name}-${git_commit}"
    elif [[ ! -z "{$pkg_branch}" ]]
    then
        pkg_url="https://github.com/${pkg_org}/${pkg_project}/archive/${pkg_branch}.zip"
        pkg_branch_clean="$(echo ${pkg_branch} | sed 's/\//-/g')"
        pkg_build="${src_dir}/${pkg_name}-${pkg_branch_clean}"
    fi

    echo "Downloading '${pkg_name}' to '${src_dir}'"
    wget --continue -O "${pkg_archive}" "${pkg_url}" &> "${pkg_download}"

    echo "Extracting '${pkg_name}' to '${src_dir}'"
    unzip -o "${pkg_archive}" -d "${src_dir}" &> "${pkg_extract}"
 
    echo "Building '${pkg_name}' from '${src_dir}'"
    cd "${src_dir}"
    eval -- "${rbinary} CMD build --no-build-vignettes \"${pkg_build}\"" &> "${build_log}"
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

elif [[ "${pkg_source}" == "local" ]]
then

    ext="tar.gz"
    pkg_archive="${build_dir}/${pkg_name}_${pkg_version}.${ext}" 
    echo "Copying local file to '${pkg_archive}'"
    cp "${pkg_url}" "${pkg_archive}"

else
    echo "ERROR: Source must be 'buildfile', 'git', or 'local'"
    exit 1
fi
