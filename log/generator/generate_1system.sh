#!/usr/bin/env bash

# Default paths
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
log_dir="$(readlink -f ./log)"
output_html="${log_dir}/1system.html"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

base_path=$(pwd)
machine_host=$(hostname)
rbinary=$(which R)
rscriptbinary=$(which Rscript)
rinfo=$(R --version)
rversion=$(echo $rinfo | sed 's/-- .*//g')
platform=$(echo $rinfo | sed -e 's/^.*Platform: //g' -e 's/R is free software.*$//')
kernelrelease=$(uname -r)
rlib=$(R_LIBS_USER=${R_LIBS_USER} Rscript -e ".libPaths()")

start_timestamp="$(cat ${log_dir}/raw/_start_timestamp.txt)"
end_timestamp="$(cat ${log_dir}/raw/_end_timestamp.txt)"

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
                    <td class=\"spec-left\">R Binary: ${rbinary}</td>
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
cat "${log_dir}/base/1system_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/1system_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${log_dir}/base/1system_bottom.html" >> "${output_html}"

