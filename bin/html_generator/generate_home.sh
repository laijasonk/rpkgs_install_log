#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0"
    echo
    echo "Flags:"
    echo "       -h Show this help message"
    exit 1
}

# Argument flag handling
while getopts "h" opt
do
    case $opt in
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh

# Default paths
output_html="${html_dir}/pages/home.html"

cat /dev/null > "${output_html}"
cat "${html_template}/home_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/home_content.html" >> "${output_html}"
cat "${html_template}/home_bottom.html" >> "${output_html}"

