#!/bin/bash

# Help message
function usage {
    echo "Usage: $0"
    echo
    echo "Flags:"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "t:h" opt
do
    case $opt in
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Define new rstudio log directory
html_base_dir="${target_dir}/rstudio_log"
html_pages_dir="${target_dir}/rstudio_log/pages"

# If rstudio logs already exist, go ahead and delete them
if [[ -d "${html_base_dir}" ]]
then
    rm -R -- "${html_base_dir}"
fi

# Copy current log to new rstudio log location
cp -R "${html_dir}" "${html_base_dir}"

# Function for converting all links to rstudio links
function convert_urls() {
    in_file="$1"
    base_dir="$(echo ${html_base_dir} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g')"
    pages_dir="$(echo ${html_pages_dir} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g')"
    sed -i 's/"\.\.\//"http:\/\/localhost:8787\/file_show?path='"${base_dir}"'\//g' ${in_file}
    sed -i 's/"\.\//"http:\/\/localhost:8787\/file_show?path='"${pages_dir}"'\//g' ${in_file}
}

# Convert the index page first
convert_urls "${html_base_dir}/index.html"

# Convert every file in the pages directory
for html_file in "${html_pages_dir}"/*.html
do 
    convert_urls "${html_file}"
done

