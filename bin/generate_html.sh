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
sidebar_template="${html_template}/sidebar_fullinstall.html"
if [[ "${log_type}" -eq 1 ]]
then
    sidebar_template="${html_template}/sidebar_fullinstall.html"
elif [[ "${log_type}" -eq 2 ]]
then
    sidebar_template="${html_template}/sidebar_artifactorybuild.html"
elif [[ "${log_type}" -eq 3 ]]
then
    sidebar_template="${html_template}/sidebar_artifactoryinstall.html"
fi

echo "Creating directory for HTML pages"
mkdir -p "${html_dir}/pages"

echo "Copying static files"
cp -R "${html_template}"/index.html "${html_dir}"
cp -R "${html_template}"/static/ "${html_dir}"
cp "${sidebar_template}" "${html_template}"/sidebar.html

echo "Generating home page"
if [[ "${log_type}" -eq 1 ]]
then
    ./bin/html_generator/generate_home.sh -1 -t "${target_dir}"
elif [[ "${log_type}" -eq 2 ]]
then
    ./bin/html_generator/generate_home.sh -2 -t "${target_dir}"
elif [[ "${log_type}" -eq 3 ]]
then
    ./bin/html_generator/generate_home.sh -3 -t "${target_dir}"
fi

echo "Generating system information page"
./bin/html_generator/generate_system.sh -t "${target_dir}"

echo "Generating input specifications page"
./bin/html_generator/generate_input.sh -t "${target_dir}"

echo "Generating pre-installation packages page"
./bin/html_generator/generate_prepackages.sh -t "${target_dir}"

echo "Generating post-installation packages page"
./bin/html_generator/generate_postpackages.sh -t "${target_dir}"

echo "Generating specific package pages"
if [[ "${log_type}" -eq 1 ]]
then
    ./bin/html_generator/generate_package_download.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_buildcheckinstall.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_install.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_test.sh -t "${target_dir}"
elif [[ "${log_type}" -eq 2 ]]
then
    ./bin/html_generator/generate_package_download.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_buildcheckinstall.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_install.sh -t "${target_dir}"
elif [[ "${log_type}" -eq 3 ]]
then
    ./bin/html_generator/generate_package_downloadartifact.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_install.sh -t "${target_dir}"
    ./bin/html_generator/generate_package_test.sh -t "${target_dir}"
fi

echo "Generating artifactory page"
if [[ "${log_type}" -eq 2 ]] || [[ "${log_type}" -eq 3 ]]
then
    ./bin/html_generator/generate_artifactory.sh -t "${target_dir}"
fi

echo "Generating summary page"
if [[ "${log_type}" -eq 1 ]]
then
    ./bin/html_generator/generate_summary_fullinstall.sh -t "${target_dir}"
elif [[ "${log_type}" -eq 2 ]]
then
    ./bin/html_generator/generate_summary_artifactorybuild.sh -t "${target_dir}"
elif [[ "${log_type}" -eq 3 ]]
then
    ./bin/html_generator/generate_summary_artifactoryinstall.sh -t "${target_dir}"
fi

echo "Copying log files"
mkdir -p "${html_dir}/log"
cp "${log_dir}"/*.* "${html_dir}"/log/

