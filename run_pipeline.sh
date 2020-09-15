#!/usr/bin/env bash
#
# Run full pipeline
#

# Default values
wait_between_commands=false

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv [-w]"
    echo "Flags:"
    echo "       -i input CSV containing a package on each newline"
    echo "       -w OPTIONAL wait between each command and wait for user"
    exit 1
}

# Argument flag handling
while getopts "i:w" opt
do
    case $opt in
        i)
            input_csv="${OPTARG}"
            ;;
        w)
            wait_between_commands=true
            ;;
        :)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Input CSV must be provided
if [[ -z "${input_csv}" ]]
then
    usage
fi

# Basic message display between each command
function header_msg() {
    echo
    echo "##################################################"
    echo "#"
    echo "# ${1}"
    echo "#"
    echo "##################################################"
    echo
    echo  "Script: ${2}"
    
    if [ ${wait_between_commands} = true ]
    then
        read -p "" null
    else
        echo
    fi
}

header_msg "Remove old files" "./bin/prune_files.sh"
./bin/prune_files.sh

header_msg "Identify missing tools and install" "./bin/identify_missing_tools.sh"
./bin/identify_missing_tools.sh

header_msg "Install source packages" "./bin/install_source_packages.sh"
./bin/install_source_packages.sh -i "${input_csv}"

header_msg "Test installed packages" "./bin/test_installed_packages.sh"
./bin/test_installed_packages.sh -i ${input_csv}

header_msg "Check source packages" "./bin/check_source_packages.sh"
./bin/check_source_packages.sh

