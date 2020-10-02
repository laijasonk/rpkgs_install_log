#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 -1 [-c config]"
    echo "       $0 -2 [-c config]"
    echo "       $0 -3 [-c config]"
    echo "Flags:"
    echo "       -1 full install log"
    echo "       -2 build artifactory log"
    echo "       -3 install artifactory log"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "123c:h" opt
do
    case $opt in
        1)
            log_type=1
            ;;
        2)
            log_type=2
            ;;
        3)
            log_type=3
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

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh #-c "${config_file}"

# Sidebar depends on type of log
if [[ "${log_type}" -eq 1 ]]
then
    sidebar_template="${html_template}/sidebar_full.html"
elif [[ "${log_type}" -eq 2 ]]
then
    sidebar_template="${html_template}/sidebar_build.html"
elif [[ "${log_type}" -eq 3 ]]
then
    sidebar_template="${html_template}/sidebar_install.html"
else
    sidebar_template="${html_template}/sidebar_full.html"
fi

echo "Copying static files"
cp -R "${html_template}"/index.html "${html_dir}"
cp -R "${html_template}"/static/ "${html_dir}"
cp "${sidebar_template}" "${html_template}"/sidebar.html

echo "Copying log files"
mkdir -p "${html_dir}/log"
cp "${log_dir}"/*.* "${html_dir}"/log/

echo "Creating directory for HTML pages"
mkdir -p "${html_dir}/pages"

echo "Generating home page"
./bin/html_generator/generate_home.sh -c "${config_file}"

echo "Generating system information page"
./bin/html_generator/generate_system.sh -c "${config_file}"

echo "Generating pre-installation packages page"
./bin/html_generator/generate_prepackages.sh -c "${config_file}"

echo "Generating source download page"
./bin/html_generator/generate_download.sh -c "${config_file}"
./bin/html_generator/generate_downloadartifact.sh -c "${config_file}"

echo "Generating specific package pages"
./bin/html_generator/generate_package_full.sh -c "${config_file}"
./bin/html_generator/generate_package_install.sh -c "${config_file}"
./bin/html_generator/generate_package_download.sh -c "${config_file}"
./bin/html_generator/generate_package_test.sh -c "${config_file}"

echo "Generating package installation page"
./bin/html_generator/generate_install.sh -c "${config_file}"

echo "Generating package check page"
./bin/html_generator/generate_check.sh -c "${config_file}"

echo "Generating artifactory status page"
./bin/html_generator/generate_artifactory.sh -c "${config_file}"

echo "Generating package test page"
./bin/html_generator/generate_test.sh -c "${config_file}"

echo "Generating post-installation packages page"
./bin/html_generator/generate_postpackages.sh -c "${config_file}"

echo "Generating summary page"
./bin/html_generator/generate_summary_full.sh -c "${config_file}"
./bin/html_generator/generate_summary_build.sh -c "${config_file}"
./bin/html_generator/generate_summary_install.sh -c "${config_file}"

