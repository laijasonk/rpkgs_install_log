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
. ./bin/global_config.sh #-c "${config_file}"

# Default paths
output_html="${html_dir}/pages/home.html"

cat /dev/null > "${output_html}"
cat "${html_template}/home_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/home_content.html" >> "${output_html}"
cat "${html_template}/home_bottom.html" >> "${output_html}"

