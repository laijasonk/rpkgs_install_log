#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 -f"
    echo "       $0 -b"
    echo "       $0 -i"
    echo "Flags:"
    echo "       -f full install log"
    echo "       -b build artifactory log"
    echo "       -i install artifactory log"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Default values
home_type=1

# Argument flag handling
while getopts "fbit:h" opt
do
    case $opt in
        f) home_type="fullinstall" ;;
        b) home_type="artifactorybuild" ;;
        i) home_type="artifactoryinstall" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

if [[ "${home_type}" == "fullinstall" ]]
then

    # Full pipeline
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_fullinstall.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"

elif [[ "${home_type}" == "artifactorybuild" ]]
then
    
    # Artifactory build
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_artifactorybuild.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"

elif [[ "${home_type}" == "artifactoryinstall" ]]
then

    # Artifactory install
    output_html="${html_dir}/pages/home.html"
    cat /dev/null > "${output_html}"
    cat "${html_template}/home_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    cat "${html_template}/home_artifactoryinstall.html" >> "${output_html}"
    cat "${html_template}/home_bottom.html" >> "${output_html}"

fi

