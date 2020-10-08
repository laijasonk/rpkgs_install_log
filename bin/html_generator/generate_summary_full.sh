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
input_csv="${log_dir}/_summary.csv"
output_html="${html_dir}/pages/summary_full.html"

html="
            <table class=\"summary-table\">
                <tr>
                    <td class=\"summary-header\">Package</td>
                    <td class=\"summary-header summary-5col center\">Download</td>
                    <td class=\"summary-header summary-5col center\">Build</td>
                    <td class=\"summary-header summary-5col center\">Check</td>
                    <td class=\"summary-header summary-5col center\">Install</td>
                    <td class=\"summary-header summary-5col center\">Test</td>
                </tr>"

function status_success() {
    html="${html}
                    <td class=\"summary-success\"><a href=\"${1}\">pass</a></td>"
}

function status_ignore() {
    html="${html}
                    <td class=\"summary-ignore\"><a href=\"${1}\">skip</a></td>"
}

function status_fail() {
    html="${html}
                    <td class=\"summary-fail\"><a href=\"${1}\">fail</a></td>"
}

while IFS=, read -r pkg_name pkg_version pkg_source download build check install artifact artifactcheck test
do
    html="${html}
                <tr>
                    <td class=\"summary-left\">${pkg_name}-${pkg_version}</td>"

    if [[ "${download}" -eq 0 ]]
    then
        status_success "package_${pkg_name}_download.html#${pkg_name}_download"
    elif [[ "${download}" -eq 2 ]]
    then
        status_ignore "package_${pkg_name}_download.html#${pkg_name}_download"
    else
        status_fail "package_${pkg_name}_download.html#${pkg_name}_download"
    fi

    if [[ "${build}" -eq 0 ]]
    then
        status_success "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build"
    elif [[ "${build}" -eq 2 ]]
    then
        status_ignore "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build"
    else
        status_fail "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_build"
    fi
 
    if [[ "${check}" -eq 0 ]]
    then
        status_success "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check"
    elif [[ "${check}" -eq 2 ]]
    then
        status_ignore "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check"
    else
        status_fail "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_check"
    fi

    if [[ "${install}" -eq 0 ]]
    then
        status_success "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install"
    elif [[ "${install}" -eq 2 ]]
    then
        status_ignore "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install"
    else
        status_fail "package_${pkg_name}_buildcheckinstall.html#${pkg_name}_install"
    fi
      
    if [[ "${test}" -eq 0 ]]
    then
        status_success "package_${pkg_name}_test.html#${pkg_name}_test"
    elif [[ "${test}" -eq 2 ]]
    then
        status_ignore "package_${pkg_name}_test.html#${pkg_name}_test"
    else
        status_fail "package_${pkg_name}_test.html#${pkg_name}_test"
    fi

    html="${html}
                </tr>"

done < "${input_csv}"

html="${html}
            </table>

            <p>Command output</p>
            <iframe class=\"log text-above space-below\" src=\"../log/_stdout.txt\" style=\"height: 500px;\"></iframe>"

cat /dev/null > "${output_html}"
cat "${html_template}/summary_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/summary_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/summary_bottom.html" >> "${output_html}"

