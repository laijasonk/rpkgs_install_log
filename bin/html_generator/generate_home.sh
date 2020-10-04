#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0"
    echo "       $0 [-t $(pwd)]"
    echo "Flags:"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "t:h" opt
do
    case $opt in
        t) target_dir="$(readlink -f ${OPTARG})" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Default paths
output_html="${html_dir}/pages/home.html"

cat /dev/null > "${output_html}"
cat "${html_template}/home_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/home_content.html" >> "${output_html}"
cat "${html_template}/home_bottom.html" >> "${output_html}"

