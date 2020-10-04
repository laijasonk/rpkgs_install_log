#!/usr/bin/env bash

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
while getopts "12c:h" opt
do
    case $opt in
        1)
            pkg_log="_preinstallation_packages.txt"
            ;;
        2)
            pkg_log="_postinstallation_packages.txt"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Conditions to run script
if [[ -z "${1}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh

# Place log in log directory
pkg_log="${log_dir}/${pkg_log}"

# Clear input installed packages list
cat /dev/null > "${pkg_log}"

echo "Exporting package snapshot to ${pkg_log}"
eval -- "${rscript} -e \"write.csv(installed.packages()[, c(2, 3, 16)], \\\"${pkg_log}\\\")\""

