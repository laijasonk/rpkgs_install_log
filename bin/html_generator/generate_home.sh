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

# Default values
home_type=1

# Argument flag handling
while getopts "123t:h" opt
do
    case $opt in
        1) home_type=1 ;;
        2) home_type=2 ;;
        3) home_type=3 ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

if [[ "${home_type}" -eq 1 ]]
then
    # Full pipeline
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_fullinstall.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"
elif [[ "${home_type}" -eq 2 ]]
then
    # Artifactory build
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_artifactorybuild.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"
elif [[ "${home_type}" -eq 3 ]]
then
    # Artifactory install
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_artifactoryinstall.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"
fi

