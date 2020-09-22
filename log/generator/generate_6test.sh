#!/usr/bin/env bash

# Default paths
log_dir="$(readlink -f ./log)"
output_html="${log_dir}/6test.html"
input_csv=$(readlink -f ./input.csv)

html=""
log_html=""
list_html=""
while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash
do
    list_html="${list_html}
                <!--li><a href=\"#${pkg_name}\">${pkg_name}</a-->
                <li>${pkg_name}
                    <ul>
                        <li style=\"font-size: smaller;\"><a href=\"#${pkg_name}_test\">Test log</a></li>
                    </ul>
                </li>"
        log_html="${log_html}
            <h2><a id=\"${pkg_name}\">${pkg_name}</a></h2>

            <p class=\"above-caption left\"><a id=\"${pkg_name}_test\" >Test log</a></p>
            <iframe class=\"log text-above\" src=\"./raw/testthat_${pkg_name}.txt\" style=\"height: 500px;\"></iframe>

            "
done < "${input_csv}"

html="${html}
            <p class=\"list-caption\" style=\"margin-top: 3em;\"><strong>Table of Contents</strong></p>
            <ul style=\"margin-top: 0; margin-bottom: 5em;\">
${list_html}
            </ul>
${log_html}"

cat /dev/null > "${output_html}"
cat "${log_dir}/base/6test_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/6test_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${log_dir}/base/6test_bottom.html" >> "${output_html}"

