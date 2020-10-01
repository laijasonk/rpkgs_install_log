#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 [-c config]"
    echo
    echo "Flags:"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "c:h" opt
do
    case $opt in
        c)
            config_file="${OPTARG}"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Load config variables and convert to absolute pathes
. ./bin/read_config.sh -c "${config_file}"



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

while IFS=, read -r pkg_name pkg_version pkg_source download build check install artifact artifactcheck test
do

    html="${html}
            <tr>
                <td class=\"summary-left\"><a href=\"package_${pkg_name}_install.html\">${pkg_name}-${pkg_version}</a></td>"

    if [[ "${install}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"package_${pkg_name}_install.html#${pkg_name}_install\">pass</a></td>"
    elif [[ "${install}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"package_${pkg_name}_install.html#${pkg_name}_install\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"package_${pkg_name}_install.html#${pkg_name}_install\">fail</a></td>"
    fi

    html="${html}
            </tr>"

done < "${input_csv}"

cat /dev/null > "${output_html}"
cat "${html_template}/install_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/install_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/install_bottom.html" >> "${output_html}"



###################################################
#
# Individual package pages
#
###################################################

# Default paths
input_csv=$(readlink -f ${log_dir}/_input.csv)

while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check pkg_covr
do

    output_html="${html_dir}/pages/package_${pkg_name}_install.html"

    html="
            <h1>Install: ${pkg_name}-${pkg_version}</h1>

            <p>Logs from install for ${pkg_name} from ${pkg_source}.</p>

            <p class=\"above-caption left\"><a id=\"${pkg_name}_install\" >Install log</a></p>
            <iframe class=\"log text-above space-below\" src=\"../log/install_${pkg_name}.txt\" style=\"height: 500px;\"></iframe>
            "

    cat /dev/null > "${output_html}"
    cat "${html_template}/package_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    echo "${html}" >> "${output_html}"
    cat "${html_template}/package_bottom.html" >> "${output_html}"

done < "${input_csv}"

