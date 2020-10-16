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
input_csv="${log_dir}/_input.csv"
output_html="${html_dir}/pages/input.html"

html="
            <table class=\"input-table\">
                <tr>
                    <td class=\"input-header input-column1\">pkg_name</td>
                    <td class=\"input-header input-column2\">pkg_version</td>
                    <td class=\"input-header input-column3\">pkg_url</td>
                    <td class=\"input-header input-column4\">pkg_source</td>
                    <td class=\"input-header input-column5\">git_commit</td>
                </tr>"

while IFS=, read -r pkg_name pkg_version pkg_url pkg_source pkg_hash
do

    html="${html}
                <tr>
                    <td class=\"input-column1\">${pkg_name}</td>
                    <td class=\"input-column2\">${pkg_version}</td>
                    <td class=\"input-column3\"><div class="oneline-overflow">${pkg_url}</div></td>
                    <td class=\"input-column4\">${pkg_source}</td>
                    <td class=\"input-column5\"><div class="oneline-overflow">${pkg_hash}</div></td>
                </tr>"

done < "${input_csv}"

html="${html}
            </table>"

cat /dev/null > "${output_html}"
cat "${html_template}/input_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/input_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/input_bottom.html" >> "${output_html}"

