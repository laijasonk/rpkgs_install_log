#!/usr/bin/env bash
#
# Duplicate HTML logs with corrected links in an RStudio Web Server
#

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
escaped_base_dir="$(echo ${html_base_dir} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g')"
escaped_pages_dir="$(echo ${html_pages_dir} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g')"

# If rstudio logs already exist, go ahead and delete them
if [[ -d "${html_base_dir}" ]]
then
    rm -R -- "${html_base_dir}"
fi

# Copy current log to new rstudio log location
cp -R "${html_dir}" "${html_base_dir}"

# Convert the index page first
index_file="${html_base_dir}/index.html"
sed -i 's/"\.\//"http:\/\/localhost:8787\/file_show?path='"${escaped_base_dir}"'\//g' ${index_file}

# Convert every file in the pages directory
for html_file in "${html_pages_dir}"/*.html
do 
    sed -i 's/"\.\.\//"http:\/\/localhost:8787\/file_show?path='"${escaped_base_dir}"'\//g' ${html_file}
    sed -i 's/"\.\//"http:\/\/localhost:8787\/file_show?path='"${escaped_pages_dir}"'\//g' ${html_file}
done

