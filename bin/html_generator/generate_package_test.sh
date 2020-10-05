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
output_html="${html_dir}/pages/package_test.html"

html="
        <table class=\"summary-table\">
            <tr>
                <td class=\"summary-header\">Package</td>
                <td class=\"summary-header summary-1col center\">Unit Test</td>
            </tr>"

while IFS=, read -r pkg_name pkg_version pkg_source download build check install artifact artifactcheck test
do

    html="${html}
            <tr>
                <td class=\"summary-left\">${pkg_name}-${pkg_version}</td>"

    if [[ "${test}" -eq 0 ]]
    then
        html="${html}
                <td class=\"summary-success\"><a href=\"package_${pkg_name}_test.html#${pkg_name}_test\">pass</a></td>"
    elif [[ "${test}" -eq 2 ]]
    then
        html="${html}
                <td class=\"summary-ignore\"><a href=\"package_${pkg_name}_test.html#${pkg_name}_test\">skip</a></td>"
    else
        html="${html}
                <td class=\"summary-fail\"><a href=\"package_${pkg_name}_test.html#${pkg_name}_test\">fail</a></td>"
    fi

    html="${html}
            </tr>"

done < "${input_csv}"

cat /dev/null > "${output_html}"
cat "${html_template}/test_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/test_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/test_bottom.html" >> "${output_html}"



###################################################
#
# Individual package pages
#
###################################################

# Default paths
input_csv=$(readlink -f ${log_dir}/_input.csv)

while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash pkg_check pkg_covr pkg_test
do

    output_html="${html_dir}/pages/package_${pkg_name}_test.html"

    html="
            <h1>Test: ${pkg_name}-${pkg_version}</h1>

            <p>Logs for unit test for ${pkg_name} from ${pkg_source}.</p>

            <p class=\"above-caption left\"><a id=\"${pkg_name}_test\" >Test log</a></p>
            <iframe class=\"log text-above\" src=\"../log/test_${pkg_name}.txt\" style=\"height: 500px;\"></iframe>
            "

    cat /dev/null > "${output_html}"
    cat "${html_template}/package_top.html" >> "${output_html}"
    cat "${html_template}/sidebar.html" >> "${output_html}"
    echo "${html}" >> "${output_html}"
    cat "${html_template}/package_bottom.html" >> "${output_html}"

done < "${input_csv}"

