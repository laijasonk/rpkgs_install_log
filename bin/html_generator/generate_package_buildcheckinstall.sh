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
output_html="${html_dir}/pages/package_buildcheckinstall.html"

html="
        <table class=\"summary-table\">
            <tr>
                <td class=\"summary-header\">Package</td>
                <td class=\"summary-header summary-3col center\">Build</td>
                <td class=\"summary-header summary-3col center\">Check</td>
                <td class=\"summary-header summary-3col center\">Install</td>
            </tr>"

while IFS=, read -r pkg_name pkg_version pkg_source download build check install test
do

    html="${html}
            <tr>
                <td class=\"summary-left\">${pkg_name}-${pkg_version}</td>"

    if [[ "${build}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build\">pass</a></td>"
    elif [[ "${build}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build\">fail</a></td>"
    fi

    if [[ "${check}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check\">pass</a></td>"
    elif [[ "${check}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check\">fail</a></td>"
    fi

    if [[ "${install}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install\">pass</a></td>"
    elif [[ "${install}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"./package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install\">fail</a></td>"
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

    output_html="${html_dir}/pages/package_${pkg_name}_buildcheckinstall.html"

    html="
            <h1>Status: ${pkg_name}-${pkg_version}</h1>

            <p class=\"space-below\">Text logs from build, check, and install for ${pkg_name} from ${pkg_source}.</p>

            <h2><a id=\"${pkg_name}_build\" >Build log</a></h2>
            <iframe class=\"log text-above space-below\" src=\"../log/build_${pkg_name}.txt\" style=\"height: 300px;\"></iframe>

            <h2><a id=\"${pkg_name}_check\" >Check log</a></h2>
            <iframe class=\"log text-above space-below\" src=\"../log/check_${pkg_name}.txt\" style=\"height: 300px;\"></iframe>

            <h2><a id=\"${pkg_name}_install\" >Install log</a></h2>
            <iframe class=\"log text-above space-below\" src=\"../log/install_${pkg_name}.txt\" style=\"height: 300px;\"></iframe>
            "

    cat /dev/null > "${output_html}"
    cat "${html_template}/package_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    echo "${html}" >> "${output_html}"
    cat "${html_template}/package_bottom.html" >> "${output_html}"

done < "${input_csv}"

