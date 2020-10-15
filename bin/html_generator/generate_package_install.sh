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



###################################################
#
# Main package page
#
###################################################

# Default paths
input_csv="${log_dir}/_summary.csv"
output_html="${html_dir}/pages/package_install.html"

html="
        <table class=\"summary-table\">
            <tr>
                <td class=\"summary-header\">Package</td>
                <td class=\"summary-header summary-1col center\">Install</td>
            </tr>"

while IFS=, read -r pkg_name pkg_version pkg_source download build check install test
do

    html="${html}
            <tr>
                <td class=\"summary-left\">${pkg_name}-${pkg_version}</td>"

    if [[ "${install}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"./package_${pkg_name}_install.html#${pkg_name}_install\">pass</a></td>"
    elif [[ "${install}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"./package_${pkg_name}_install.html#${pkg_name}_install\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"./package_${pkg_name}_install.html#${pkg_name}_install\">fail</a></td>"
    fi

    html="${html}
            </tr>"

done < "${input_csv}"

cat /dev/null > "${output_html}"
cat "${html_template}/package_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/package_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/package_bottom.html" >> "${output_html}"



###################################################
#
# Individual package pages
#
###################################################

# Default paths
input_csv=$(readlink -f ${log_dir}/_input.csv)

while IFS=, read -r pkg_name pkg_version pkg_url pkg_source git_commit
do

    output_html="${html_dir}/pages/package_${pkg_name}_install.html"

    html="
            <h1>Install: ${pkg_name}-${pkg_version}</h1>

            <p class=\"space-below\">Text logs from installing ${pkg_name} from ${pkg_source}.</p>

            <h2><a id=\"${pkg_name}_install\" >Install log</a></h2>
            <iframe class=\"log text-above space-below\" src=\"../log/install_${pkg_name}.txt\" style=\"height: 500px;\"></iframe>
            "

    cat /dev/null > "${output_html}"
    cat "${html_template}/package_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    echo "${html}" >> "${output_html}"
    cat "${html_template}/package_bottom.html" >> "${output_html}"

done < "${input_csv}"

