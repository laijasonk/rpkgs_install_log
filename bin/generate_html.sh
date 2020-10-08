#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 -1"
    echo "       $0 -2"
    echo "       $0 -3"
    echo "Flags:"
    echo "       -1 full install log"
    echo "       -2 build artifactory log"
    echo "       -3 install artifactory log"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "123t:h" opt
do
    case $opt in
        1) log_type=1 ;;
        2) log_type=2 ;;
        3) log_type=3 ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

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

echo "Creating directory for HTML pages"
mkdir -p "${html_dir}/pages"

echo "Generating home page"
./bin/html_generator/generate_home.sh

echo "Generating system information page"
./bin/html_generator/generate_system.sh

echo "Generating pre-installation packages page"
./bin/html_generator/generate_prepackages.sh

echo "Generating input specifications page"
./bin/html_generator/generate_input.sh

#echo "Generating source download page"
#./bin/html_generator/generate_download.sh
#./bin/html_generator/generate_downloadartifact.sh

echo "Generating specific package pages"
./bin/html_generator/generate_package_buildcheckinstall.sh
#./bin/html_generator/generate_package_install.sh
./bin/html_generator/generate_package_download.sh
./bin/html_generator/generate_package_test.sh

#echo "Generating package installation page"
#./bin/html_generator/generate_install.sh

#echo "Generating package check page"
#./bin/html_generator/generate_check.sh

#echo "Generating artifactory status page"
#./bin/html_generator/generate_artifactory.sh

#echo "Generating package test page"
#./bin/html_generator/generate_test.sh

echo "Generating post-installation packages page"
./bin/html_generator/generate_postpackages.sh

echo "Generating summary page"
./bin/html_generator/generate_summary_full.sh
#./bin/html_generator/generate_summary_build.sh
#./bin/html_generator/generate_summary_install.sh

echo "Copying static files"
cp -R "${html_template}"/index.html "${html_dir}"
cp -R "${html_template}"/static/ "${html_dir}"
cp "${sidebar_template}" "${html_template}"/sidebar.html

echo "Copying log files"
mkdir -p "${html_dir}/log"
cp "${log_dir}"/*.* "${html_dir}"/log/

