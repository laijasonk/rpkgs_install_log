#!/usr/bin/env bash
#
# Store the list of installed R packages into a text log 
#

# Help message
function usage {
    echo "Usage: $0 -1 [-t $(pwd)]"
    echo "       $0 -2 [-t $(pwd)]"
    echo "Flags:"
    echo "       -1 Save pre-installation packages"
    echo "       -2 Save post-installation packages"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "12t:h" opt
do
    case $opt in
        1) pkg_log="_preinstallation_packages.txt" ;;
        2) pkg_log="_postinstallation_packages.txt" ;;
        t) target_dir="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${1}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Place log in log directory
pkg_log="${log_dir}/${pkg_log}"

# Clear input installed packages list
cat /dev/null > "${pkg_log}"

echo "Exporting package snapshot to ${pkg_log}"
eval -- "${rscript} -e \"write.csv(installed.packages()[, c(2, 3, 16)], \\\"${pkg_log}\\\")\""

