#!/usr/bin/env bash
#
# Download and build source packages
# 
# Default values
curr_dir=$(pwd)

# Help message
function usage {
    echo "Usage: $0 -n name -v version -u http://buildurl -s 'buildfile'"
    echo "       $0 -n name -v version -u http://github/hash -s 'sourcecode'"
    echo "       $0 -n name -v version -u http://cloneurl -s 'git' -c checkout_sha"
    echo "       $0 -n name -v version -u /path/to/url -s 'local'"
    echo "Flags:"
    echo "       -n package name"
    echo "       -v package version number"
    echo "       -u http url or local path to package archive"
    echo "       -s source type (currently supported: 'build', 'sourcecode', or 'git')"
    echo "       -c OPTIONAL git commit SHA (required if sourcetype='git')"
    echo "       -t OPTIONAL path to target directory"
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
    usage
elif [[ "${pkg_source}" == "build" ]] || [[ "${pkg_source}" == "sourcecode" ]]
then
    :
elif [[ "${pkg_source}" == "git" ]] && [[ ! -z "${git_commit}" ]] 
then
    :
else
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
if [[ "${pkg_source}" == "build" ]]
then
    
    # NOTE: ALWAYS ASSUMES TAR.GZ
    ext="tar.gz"

    # Define variables
    pkg_archive="${build_dir}/${pkg_name}_${pkg_version}.${ext}" 
    sourcecode_dir="${src_dir}/${pkg_name}"

    # Download
    echo "Downloading '${pkg_name}' to '${src_dir}'"
    if [[ "${pkg_url:0:4}" == "http" ]]
    then
        cmd="wget --continue -O \"${pkg_archive}\" \"${pkg_url}\""
    else
        cmd="if [[ ! -f \"${pkg_archive}\" ]]; then cp \"${pkg_url}\" \"${pkg_archive}\" && echo \"Success: Build file copied to artifact\"; else echo \"Success: Artifact found\"; fi"

        # Special case for artifactories
        if [[ -f "$(dirname ${pkg_url})/${pkg_name}.txt" ]]
        then
            cp "$(dirname ${pkg_url})/${pkg_name}.txt" "${build_dir}"
        fi
    fi
    run_and_log_cmd "${cmd}" "${download_log}"

    # Logs
    echo "Extract step skipped because the build file was already provided for '${pkg_name}'" > "${extract_log}"
    echo "Build step skipped because the build file was already provided for '${pkg_name}'" > "${build_log}"

elif [[ "${pkg_source}" == "sourcecode" ]]
then

    # Determine extension
    if [[ "${pkg_url:(-4)}" == ".zip" ]]
    then
        ext="zip"
    elif [[ "${pkg_url:(-7)}" == ".tar.gz" ]]
    then
        ext="tar.gz"
    elif [[ "${pkg_url:(-8)}" == ".tar.bz2" ]]
    then
        ext="tar.bz2"
    elif [[ "${pkg_url:(-4)}" == ".rar" ]]
    then
        ext="rar"
    else
        ext="tar.gz"
    fi

    # Define variables
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 

    # Download
    echo "Downloading '${pkg_name}' to '${src_dir}'"
    if [[ "${pkg_url:0:4}" == "http" ]]
    then
        cmd="wget --continue -O \"${pkg_archive}\" \"${pkg_url}\""
    else
        cmd="cp \"${pkg_url}\" \"${pkg_archive}\""
    fi
    run_and_log_cmd "${cmd}" "${download_log}"

    # Extract
    echo "Extracting '${pkg_name}' to '${src_dir}'"
    if [[ "${ext}" == "zip" ]]
    then
        cmd="unzip -o \"${pkg_archive}\" -d \"${src_dir}/\""
        out_dir="$(dirname $(unzip -Z1 ${pkg_archive} | head -1).tmp)"
        sourcecode_dir="${src_dir}/${out_dir}"
    elif [[ "${ext}" == "tar.gz" ]] || [[ "${ext}" == "tar.bz2" ]]
    then
        cmd="tar xvf \"${pkg_archive}\" --directory \"${src_dir}/\""
        out_dir=$(dirname $(tar -tf ${pkg_archive} | head -1).tmp)
        sourcecode_dir="${src_dir}/${out_dir}"
    elif [[ "${ext}" == "rar" ]]
    then
        cmd="unrar x \"${pkg_archive}\" \"${src_dir}/\""
        out_dir=$(dirname $(unrar tb ${pkg_archive} | head -1).tmp)
        sourcecode_dir="${src_dir}/${out_dir}"
    else
        echo "ERROR: Unrecognizable extension"
        exit 1
    fi
    run_and_log_cmd "${cmd}" "${extract_log}"
 
    # Build
    echo "Building '${pkg_name}' from '${src_dir}'"
    cd "${src_dir}"
    cmd="R_LIBS=${R_LIBS} ${rbinary} CMD build --no-build-vignettes \"${sourcecode_dir}\""
    run_and_log_cmd "${cmd}" "${build_log}"
    # Assumes build tarball is printed on 3rd to last line in the build_log
    tarball="$(cat ${build_log} | sed '/^$/d' | head -n -2 | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
    echo -e "\n\n----------\nExit status: $?">> "${build_log}"
    cd "${curr_dir}"

    # Move
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

    # ASSUMES $pkg_url IS THE REPO CLONE URL
    # ASSUMES $git_commit IS PROVIDED

    # Define variables
    pkg_archive="${src_dir}/${pkg_name}_${pkg_version}.${ext}" 
    download_url="${pkg_url}/${git_commit}.zip"
    sourcecode_dir="${src_dir}/${pkg_name}-${git_commit}"

    # Clone
    echo "Cloning '${pkg_name}' to '${src_dir}'"
    cd "${src_dir}"
    if [[ -d "${sourcecode_dir}" ]]
    then
        touch "${sourcecode_dir}" && rm -R -- "$(readlink -f ${sourcecode_dir})"
    fi
    cmd="git clone \"${pkg_url}\" \"${sourcecode_dir}/\""
    run_and_log_cmd "${cmd}" "${download_log}"
    cd "${curr_dir}"

    # Checkout
    echo "Checkout '${git_commit}' for '${pkg_name}'"
    cd "${sourcecode_dir}"
    cmd="git checkout ${git_commit}"
    run_and_log_cmd "${cmd}" "${extract_log}"
    cd "${curr_dir}"
 
    # Build
    echo "Building '${pkg_name}' from '${src_dir}'"
    cd "${src_dir}"
    cmd="${rbinary} CMD build --no-build-vignettes \"${sourcecode_dir}\""
    run_and_log_cmd "${cmd}" "${build_log}"
    # Assumes build tarball is printed on 3rd to last line in the build_log
    tarball="$(cat ${build_log} | sed '/^$/d' | head -n -2 | tail -1 | sed -e 's/^.*‘//' -e 's/’.*$//')"
    cd "${curr_dir}"

    # Move
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

else

    echo "ERROR: Source must be 'buildfile', 'sourcecode', or 'git'"
    exit 1

fi

