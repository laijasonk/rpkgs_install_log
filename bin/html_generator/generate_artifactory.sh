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
artifactory_list="${log_dir}/_artifactory.txt"
output_html="${html_dir}/pages/artifactory.html"

html="
            <table class=\"summary-table\">
                <tr>
                    <td class=\"summary-header\">Artifact Package</td>
                </tr>"

while read -r buildfile
do
    html="${html}
                <tr>
                    <td class=\"summary-1col\"><div class=\"oneline-overflow\">${buildfile}</div></td>
                </tr>"

done < "${artifactory_list}"

html="${html}
            </table>"

cat /dev/null > "${output_html}"
cat "${html_template}/artifactory_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/artifactory_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/artifactory_bottom.html" >> "${output_html}"

