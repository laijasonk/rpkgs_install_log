#!/usr/bin/env bash
#
# Download and build source packages
# 
# Default values
curr_dir=$(pwd)

# Help message
function usage {
    echo "Usage: $0 -n name -v version -u http://buildurl -s 'buildfile'"
    echo "       $0 -n name -v version -u http://github/hash -s 'source'"
    echo "       $0 -n name -v version -u http://cloneurl -s 'git' -c checkout_sha"
    echo "       $0 -n name -v version -u /path/to/url -s 'local'"
    echo "Flags:"
    echo "       -n package name"
    echo "       -v package version number"
    echo "       -u file url (if source=buildfile or github) or path to tarball (if source=local)"
    echo "       -s source (currently supported: 'buildfile', 'source', 'git', or 'local')"
    echo "       -h git commit SHA hash"
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
download_log="${log_dir}/download_${pkg_name}.txt"
extract_log="${log_dir}/extract_${pkg_name}.txt"
build_log="${log_dir}/build_${pkg_name}.txt"

# Download instructions for different sources
if [[ "${pkg_source}" == "buildfile" ]]
then
    
    # WARNING: CURRENTLY ASSUMES TAR.GZ

    # Define variables
    ext="tar.gz"
    pkg_archive="${build_dir}/${pkg_name}_${pkg_version}.${ext}" 
    pkg_build="${src_dir}/${pkg_name}"

    echo "Downloading '${pkg_name}' to '${src_dir}'"
    cmd="wget --continue -O \"${pkg_archive}\" \"${pkg_url}\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${download_log}"
    eval -- "${cmd}" >> "${download_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${download_log}"

    echo "Extract step skipped because the build file was already provided for '${pkg_name}'" > "${extract_log}"
    echo "Build step skipped because the build file was already provided for '${pkg_name}'" > "${build_log}"

elif [[ "${pkg_source}" == "source" ]]
then

    # WARNING: CURRENTLY ASSUMES ZIP

    # Define variables
    ext="zip"
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 
    download_url="${pkg_url}/${git_commit}.zip"
    pkg_build="${src_dir}/${pkg_name}-${git_commit}"

    echo "Downloading '${pkg_name}' to '${src_dir}'"
    cmd="wget --continue -O \"${pkg_archive}\" \"${download_url}\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${download_log}"
    eval -- "${cmd}" >> "${download_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${download_log}"

    echo "Extracting '${pkg_name}' to '${src_dir}'"
    cmd="unzip -o \"${pkg_archive}\" -d \"${src_dir}\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${extract_log}"
    eval -- "${cmd}" >> "${extract_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${extract_log}"
 
    echo "Building '${pkg_name}' from '${src_dir}'"
    cd "${src_dir}"
    cmd="${rbinary} CMD build --no-build-vignettes \"${pkg_build}\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${build_log}"
    eval -- "${cmd}" >> "${build_log}" 2>&1
    tarball="$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
    echo -e "\n\n----------\nExit status: $?">> "${build_log}"
    cd "${curr_dir}"
      
    echo "Moving build tarball to '${build_dir}'"
    src_tarball="${src_dir}/${tarball}"
    build_tarball="${build_dir}/${tarball}"
    if [[ -f "${src_tarball}" ]]
    then
        mv "${src_tarball}" "${build_tarball}"
    else
        echo "ERROR: Build tarball does not exist; build probably failed"
        exit 1
    fi

elif [[ "${pkg_source}" == "git" ]]
then

    # ASSUMES pkg_url IS THE CLONE HTTP URL

    # Define variables
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 
    download_url="${pkg_url}/${git_commit}.zip"
    pkg_build="${src_dir}/${pkg_name}-${git_commit}"

    echo "Cloning '${pkg_name}' to '${src_dir}'"
    cd "${src_dir}"
    cmd="git clone \"${pkg_url}\" \"${pkg_build}/\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${download_log}"
    eval -- "${cmd}" >> "${download_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${download_log}"
    cd "${curr_dir}"

    echo "Checkout '${git_commit}' for '${pkg_name}'"
    cd "${pkg_build}"
    cmd="git checkout ${git_commit}"
    echo -e "CMD: ${cmd}\n----------\n\n" > "${extract_log}"
    eval -- "${cmd}" >> "${extract_log}" 2>&1
    echo -e "\n\n----------\nExit status: $?">> "${extract_log}"
    cd "${curr_dir}"
 
    echo "Building '${pkg_name}' from '${src_dir}'"
    cd "${src_dir}"
    cmd="${rbinary} CMD build --no-build-vignettes \"${pkg_build}\""
    echo -e "CMD: ${cmd}\n----------\n\n" > "${build_log}"
    eval -- "${cmd}" >> "${build_log}" 2>&1
    tarball="$(cat ${build_log} | sed '/^$/d' | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
    echo -e "\n\n----------\nExit status: $?">> "${build_log}"
    cd "${curr_dir}"
      
    echo "Moving build tarball to '${build_dir}'"
    src_tarball="${src_dir}/${tarball}"
    build_tarball="${build_dir}/${tarball}"
    if [[ -f "${src_tarball}" ]]
    then
        mv "${src_tarball}" "${build_tarball}"
    else
        echo "ERROR: Build tarball does not exist; build probably failed"
        exit 1
    fi


elif [[ "${pkg_source}" == "local" ]]
then

    ext="tar.gz"
    pkg_archive="${build_dir}/${pkg_name}_${pkg_version}.${ext}" 
    echo "Copying local file to '${pkg_archive}'"
    cp "${pkg_url}" "${pkg_archive}"
    
    echo "Download step skipped because input file is local for '${pkg_name}'" > "${download_log}"
    echo "Extract step skipped because input file is local for '${pkg_name}'" > "${extract_log}"
    echo "Build step skipped because input file is local for '${pkg_name}'" > "${build_log}"

else

    echo "ERROR: Source must be 'buildfile', 'github', or 'local'"
    exit 1

fi
