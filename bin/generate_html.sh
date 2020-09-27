#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 [-c config]"
    echo
    echo "Flags:"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "c:h" opt
do
    case $opt in
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

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"

echo "Copying static files"
cp -R "${html_template}"/static/ "${html_dir}"

echo "Copying log files"
mkdir -p "${html_dir}/log"
cp "${log_dir}"/*.txt "${html_dir}"/log/

echo "Generating home page"
./bin/html_generator/generate_0home.sh -c "${config_file}"

echo "Generating system information page"
./bin/html_generator/generate_1system.sh -c "${config_file}"

echo "Generating pre-installation packages page"
./bin/html_generator/generate_2prepackages.sh -c "${config_file}"

echo "Generating source download/build page"
./bin/html_generator/generate_3downloadbuild.sh -c "${config_file}"

echo "Generating package installation page"
./bin/html_generator/generate_4install.sh -c "${config_file}"

echo "Generating package check page"
./bin/html_generator/generate_5check.sh -c "${config_file}"

echo "Generating artifactory status page"
./bin/html_generator/generate_6artifactory.sh -c "${config_file}"

echo "Generating package test page"
./bin/html_generator/generate_7test.sh -c "${config_file}"

echo "Generating post-installation packages page"
./bin/html_generator/generate_8postpackages.sh -c "${config_file}"

echo "Generating summary page"
./bin/html_generator/generate_9summary.sh -c "${config_file}"

