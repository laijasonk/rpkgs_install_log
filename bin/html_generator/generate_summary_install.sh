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

# Default paths
input_csv="${log_dir}/_summary.csv"
output_html="${html_dir}/pages/summary_install.html"

html="
            <table class=\"summary-table\">
                <tr>
                    <td class=\"summary-header\">Package</td>
                    <td class=\"summary-header summary-4col center\">Artifact</td>
                    <td class=\"summary-header summary-4col center\">Check</td>
                    <td class=\"summary-header summary-4col center\">Install</td>
                    <td class=\"summary-header summary-4col center\">Test</td>
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
                    <td class=\"summary-left\">${pkg_name}</td>"

    if [[ "${artifact}" -eq 0 ]]
    then
        status_success "artifactory.html#${pkg_name}_artifact"
    elif [[ "${artifact}" -eq 2 ]]
    then
        status_ignore "artifactory.html#${pkg_name}_artifact"
    else
        status_fail "artifactory.html#${pkg_name}_artifact"
    fi
  
    if [[ "${artifactcheck}" -eq 0 ]]
    then
        status_success "artifactory.html#${pkg_name}_artifactcheck"
    elif [[ "${artifactcheck}" -eq 2 ]]
    then
        status_ignore "artifactory.html#${pkg_name}_artifactcheck"
    else
        status_fail "artifactory.html#${pkg_name}_artifactcheck"
    fi

    if [[ "${install}" -eq 0 ]]
    then
        status_success "install.html#${pkg_name}_install"
    elif [[ "${install}" -eq 2 ]]
    then
        status_ignore "install.html#${pkg_name}_install"
    else
        status_fail "install.html#${pkg_name}_install"
    fi

    if [[ "${test}" -eq 0 ]]
    then
        status_success "test.html#${pkg_name}_test"
    elif [[ "${test}" -eq 2 ]]
    then
        status_ignore "test.html#${pkg_name}_test"
    else
        status_fail "test.html#${pkg_name}_test"
    fi

    html="${html}
                </tr>"

done < "${input_csv}"

html="${html}
            </table>

            <p>Command output</p>
            <iframe class=\"log text-above space-below\" src=\"../log/_stdout.txt\" style=\"height: 300px;\"></iframe>"

cat /dev/null > "${output_html}"
cat "${html_template}/summary_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/summary_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/summary_bottom.html" >> "${output_html}"

