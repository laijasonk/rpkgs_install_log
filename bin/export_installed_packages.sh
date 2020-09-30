#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 -1 [-c config]"
    echo "       $0 -2 [-c config]"
    echo "Flags:"
    echo "       -1 Save pre-installation packages"
    echo "       -2 Save post-installation packages"
    echo "       -c OPTIONAL path to config file"
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
        c)
            config_file="${OPTARG}"
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
. ./bin/read_config.sh -c "${config_file}"

# Place log in log directory
pkg_log="${log_dir}/${pkg_log}"

# Clear input installed packages list
cat /dev/null > "${pkg_log}"

echo "Exporting package snapshot to ${pkg_log}"
Rscript -e "write.csv(installed.packages()[, c(2, 3, 16)], \"${pkg_log}\")"

