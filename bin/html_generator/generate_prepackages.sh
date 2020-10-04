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
        t) target_dir="$(readlink -f ${OPTARG})" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Default paths
input_csv="${log_dir}/_preinstallation_packages.txt"
output_html="${html_dir}/pages/prepackages.html"
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
cat "${html_template}/prepackages_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/prepackages_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/prepackages_bottom.html" >> "${output_html}"

