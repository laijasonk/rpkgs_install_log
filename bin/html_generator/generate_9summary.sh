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
output_html="${html_dir}/9summary.html"

html="
        <table class=\"summary-table\">
            <tr>
                <td class=\"summary-header\">Package</td>
                <td class=\"summary-header center\">Download</td>
                <td class=\"summary-header center\">Build</td>
                <td class=\"summary-header center\">Install</td>
                <td class=\"summary-header center\">Check</td>
                <td class=\"summary-header center\">Art.File</td>
                <td class=\"summary-header center\">Art.Check</td>
                <td class=\"summary-header center\">Art.Install</td>
                <td class=\"summary-header center\">Test</td>
            </tr>"

function status_success() {
    html="${html}
                <td class=\"summary-success\"><a href=\"${1}\">O</a></td>"
}

function status_ignore() {
    html="${html}
                <td class=\"summary-ignore\"><a href=\"${1}\">--</a></td>"
}

function status_fail() {
    html="${html}
                <td class=\"summary-fail\"><a href=\"${1}\">X</a></td>"
}

while IFS=, read -r pkg_name pkg_version pkg_source download build install check artifactfile artifactcheck artifactinstall test
do
    html="${html}
            <tr>
                <td class=\"summary-left\">${pkg_name}</td>"

    if [[ "${download}" -eq 0 ]]
    then
        status_success "3downloadbuild.html#${pkg_name}_download"
    elif [[ "${download}" -eq 2 ]]
    then
        status_ignore "3downloadbuild.html#${pkg_name}_download"
    else
        status_fail "3downloadbuild.html#${pkg_name}_download"
    fi

    if [[ "${build}" -eq 0 ]]
    then
        status_success "3downloadbuild.html#${pkg_name}_build"
    elif [[ "${build}" -eq 2 ]]
    then
        status_ignore "3downloadbuild.html#${pkg_name}_build"
    else
        status_fail "3downloadbuild.html#${pkg_name}_build"
    fi

    if [[ "${install}" -eq 0 ]]
    then
        status_success "4install.html#${pkg_name}_install"
    elif [[ "${install}" -eq 2 ]]
    then
        status_ignore "4install.html#${pkg_name}_install"
    else
        status_fail "4install.html#${pkg_name}_install"
    fi
   
    if [[ "${check}" -eq 0 ]]
    then
        status_success "5check.html#${pkg_name}_check"
    elif [[ "${check}" -eq 2 ]]
    then
        status_ignore "5check.html#${pkg_name}_check"
    else
        status_fail "5check.html#${pkg_name}_check"
    fi
    
    if [[ "${artifactfile}" -eq 0 ]]
    then
        status_success "6artifactory.html#${pkg_name}_artifactfile"
    elif [[ "${artifactfile}" -eq 2 ]]
    then
        status_ignore "6artifactory.html#${pkg_name}_artifactfile"
    else
        status_fail "6artifactory.html#${pkg_name}_artifactfile"
    fi
  
    if [[ "${artifactcheck}" -eq 0 ]]
    then
        status_success "6artifactory.html#${pkg_name}_artifactcheck"
    elif [[ "${artifactcheck}" -eq 2 ]]
    then
        status_ignore "6artifactory.html#${pkg_name}_artifactcheck"
    else
        status_fail "6artifactory.html#${pkg_name}_artifactcheck"
    fi

    if [[ "${artifactinstall}" -eq 0 ]]
    then
        status_success "6artifactory.html#${pkg_name}_artifactinstall"
    elif [[ "${artifactinstall}" -eq 2 ]]
    then
        status_ignore "6artifactory.html#${pkg_name}_artifactinstall"
    else
        status_fail "6artifactory.html#${pkg_name}_artifactinstall"
    fi

    if [[ "${test}" -eq 0 ]]
    then
        status_success "7test.html#${pkg_name}_test"
    elif [[ "${test}" -eq 2 ]]
    then
        status_ignore "7test.html#${pkg_name}_test"
    else
        status_fail "7test.html#${pkg_name}_test"
    fi

    html="${html}
            </tr>"
done < "${input_csv}"

cat /dev/null > "${output_html}"
cat "${html_dir}/base/9summary_top.html" >> "${output_html}"
cat "${html_dir}/base/sidebar.html" >> "${output_html}"
cat "${html_dir}/base/9summary_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_dir}/base/9summary_bottom.html" >> "${output_html}"

