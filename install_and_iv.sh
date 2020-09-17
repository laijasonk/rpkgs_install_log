#!/usr/bin/env bash
#
# Run full pipeline
#

# Default values
wait_between_packages=false

# Help message
function usage {
    echo "Usage: $0 -i input.yaml"
    echo "       $0 -i input.yaml [-w]"
    echo "Flags:"
    echo "       -i input yaml containing release packages"
    echo "       -w OPTIONAL stop between each package and wait for user"
    exit 1
}

# Argument flag handling
while getopts "i:w" opt
do
    case $opt in
        i)
            input_yaml="$(readlink -f ${OPTARG})"
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
if [[ -z "${input_yaml}" ]]
then
    usage
fi

# Variables
input_csv=$(readlink -f ./input.csv)


# Basic message display between each package
function header_msg() {
    echo
    echo "##################################################"
    echo "#"
    echo "# ${1}"
    echo "#"
    echo "##################################################"
    echo
    
    if [ ${wait_between_packages} = true ]
    then
        read -p "" null
    else
        echo
    fi
}

header_msg "Initializing system"
./bin/clean_install.sh
./bin/yaml_to_csv.sh \
    -i ${input_yaml} \
    -o "${input_csv}"
#./bin/identify_missing_tools.sh

while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash
do
    header_msg "${pkg_name}-${pkg_version}"

    ./bin/download_source_package.sh \
        -n "${pkg_name}" \
        -v "${pkg_version}" \
        -s "${pkg_source}" \
        -o "${pkg_org}" \
        -p "${pkg_repo}" \
        -b "${pkg_branch}" \
        -h "${pkg_hash}"

    ./bin/install_source_package.sh \
        -i "./src/${pkg_name}_${pkg_version}.tar.gz"

    ./bin/test_installed_package.sh \
        -i "${pkg_name}"

    ./bin/check_source_package.sh \
        -i "./src/${pkg_name}_${pkg_version}.tar.gz"

done < "${input_csv}"

