#!/usr/bin/env bash

# Default paths
log_dir="$(readlink -f ./log)"
input_csv="${log_dir}/raw/_preinstallation_packages.txt"
output_html="${log_dir}/2prepackages.html"
row_num=0

html="
            <table class=\"pkg-table\">"
while IFS=, read -r pkg_name pkg_library pkg_version pkg_r
do
    if [[ ${row_num} == 0 ]]
    then
        html="${html}
                    <tr>
                        <td class=\"pkg-column1 pkg-header\">Package</td>
                        <td class=\"pkg-column2 pkg-header\">LibPath</td>
                        <td class=\"pkg-column3 pkg-header\">Version</td>
                        <td class=\"pkg-column4 pkg-header\">Built</td>
                    </tr>
        "
    else
        html="${html}
                    <tr>
                        <td class=\"pkg-column1\">${pkg_name}</td>
                        <td class=\"pkg-column2\">${pkg_library}</td>
                        <td class=\"pkg-column3\">${pkg_version}</td>
                        <td class=\"pkg-column4\">${pkg_r}</td>
                    </tr>
        "
    fi
    row_num=$((row_num+1))
done < "${input_csv}"

cat /dev/null > "${output_html}"
cat "${log_dir}/base/2prepackages_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/2prepackages_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${log_dir}/base/2prepackages_bottom.html" >> "${output_html}"

