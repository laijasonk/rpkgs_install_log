#!/usr/bin/env bash

lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
log_dir="$(readlink -f ./log/raw)"

# Help message
function usage {
    echo "Usage: $0 -1"
    echo "       $0 -2"
    echo "Flags:"
    echo "       -1 Save pre-installation packages"
    echo "       -2 Save post-installation packages"
    exit 1
}

# Argument flag handling
while getopts "12h" opt
do
    case $opt in
        1)
            pkg_log="${log_dir}/_preinstallation_packages.txt"
            ;;
        2)
            pkg_log="${log_dir}/_postinstallation_packages.txt"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# An option must be passed
if [[ -z "${1}" ]]
then
    usage
fi

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}" "${log_dir}"

# Clear packages list
cat /dev/null > "${pkg_log}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

echo "Exporting installed package snapshot to ${pkg_log}"
Rscript -e "write.csv(installed.packages()[, c(2, 3, 16)], \"${pkg_log}\")"

echo

