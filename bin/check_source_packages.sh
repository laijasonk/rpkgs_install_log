#!/usr/bin/env bash
#
# Check source packages
#

# Default values (TODO: add option flags)
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
src_dir="$(readlink -f ./src)"
build_dir="$(readlink -f ./build)"
log_dir="$(readlink -f ./log)"
check_dir="${src_dir}/_check"
dl_pkgs_log="${log_dir}/_downloaded_packages.log"

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${src_dir}" "${build_dir}" "${log_dir}" "${check_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Extract every specified package into the check directory
while read -r dl_pkg
do
    archive_name="$(basename ${dl_pkg})"
    extract_log="${log_dir}/extract_${archive_name}.log"
    
    echo "Extracting ${archive_name} for checking"

    if [[ "${dl_pkg:(-7)}" == ".tar.gz" ]]
    then
        tar xvf "${dl_pkg}" --directory "${check_dir}" &> "${extract_log}"
    elif [[ "${dl_pkg:(-8)}" == ".tar.bz2" ]]
    then
        tar xvf "${dl_pkg}" --directory "${check_dir}" &> "${extract_log}"
    elif [[ "${dl_pkg:(-4)}" == ".zip" ]]
    then
        unzip "${dl_pkg}" -d  "${check_dir}" &> "${extract_log}"
    elif [[ "${dl_pkg:(-4)}" == ".rar" ]]
    then
        unrar x "${dl_pkg}" "${check_dir}" &> "${extract_log}"
    else
        echo "Unrecognized extension on ${dl_pkg}" > "${extract_log}"
        cat "${extract_log}"
        exit 1
    fi
done < "${dl_pkgs_log}"

# Copy every source directory to the check directory
for pkg_src in "${src_dir}"/[!_]*/
do
    echo "Copying ${pkg_src} for checking "
    cp -R "${pkg_src}" ${check_dir}
done

# Nicer display
echo

# Check and log every package in check directory
for pkg_dir in ${check_dir}/*/
do
    pkg_name=$(basename ${pkg_dir%/})
    echo "Checking package ${pkg_name}"
    check_log="${log_dir}/check_${pkg_name}.log"
    Rscript -e "devtools::check(\"${pkg_dir}\")" &> "${check_log}"
    echo "Results saved to ${check_log}"
    echo
done

