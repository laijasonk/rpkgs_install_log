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
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Default paths
output_html="${html_dir}/pages/system.html"

# System information
base_path=$(pwd)
target_path=${target_dir}
machine_host=$(hostname)
rbinary=$(cat ${log_dir}/_rbinary.txt)
rscriptbinary=$(cat ${log_dir}/_rscript.txt)
rinfo=$(R --version)
rversion=$(echo $rinfo | sed 's/-- .*//g')
platform=$(echo $rinfo | sed -e 's/^.*Platform: //g' -e 's/R is free software.*$//')
kernelrelease=$(uname -r)
rlib="$(echo ${lib_dir}:${rlibs} | sed 's/:/, /g')"

start_timestamp="$(cat ${log_dir}/_start_timestamp.txt)"
end_timestamp="$(cat ${log_dir}/_end_timestamp.txt)"

html="
            <table class=\"spec-table\">
                <tr>
                    <td class=\"spec-header\">Information</td>
                    <td class=\"spec-header\">Value</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Base Path</td>
                    <td class=\"spec-right\">${base_path}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Target Path</td>
                    <td class=\"spec-right\">${target_path}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Platform</td>
                    <td class=\"spec-right\">${platform}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Machine Hostname</td>
                    <td class=\"spec-right\">${machine_host}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Kernel Release</td>
                    <td class=\"spec-right\">${kernelrelease}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">R Version</td>
                    <td class=\"spec-right\">${rversion}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">R Binary</td>
                    <td class=\"spec-right\">${rbinary}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Rscript Binary</td>
                    <td class=\"spec-right\">${rscriptbinary}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">R Libaries</td>
                    <td class=\"spec-right\">${rlib}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">Start Timestamp</td>
                    <td class=\"spec-right\">${start_timestamp}</td>
                </tr>
                <tr>
                    <td class=\"spec-left\">End Timestamp</td>
                    <td class=\"spec-right\">${end_timestamp}</td>
                </tr>
            </table>
"

cat /dev/null > "${output_html}"
cat "${html_template}/system_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/system_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/system_bottom.html" >> "${output_html}"

