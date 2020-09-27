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
output_html="${html_dir}/5check.html"
input_csv=$(readlink -f ./input.csv)

html=""
log_html=""
list_html=""
while IFS=, read -r pkg_name pkg_version pkg_source pkg_org pkg_repo pkg_branch pkg_hash
do
    list_html="${list_html}
                <!--li><a href=\"#${pkg_name}\">${pkg_name}</a-->
                <li>${pkg_name}
                    <ul>
                        <li style=\"font-size: smaller;\"><a href=\"#${pkg_name}_check\">Check log</a></li>
                    </ul>
                </li>"
        log_html="${log_html}
            <h2><a id=\"${pkg_name}\">${pkg_name}</a></h2>

            <p class=\"above-caption left\"><a id=\"${pkg_name}_check\" >Check log</a></p>
            <iframe class=\"log text-above\" src=\"./log/check_${pkg_name}.txt\" style=\"height: 500px;\"></iframe>

            "
done < "${input_csv}"

html="${html}
            <p class=\"list-caption\" style=\"margin-top: 3em;\"><strong>Table of Contents</strong></p>
            <ul style=\"margin-top: 0; margin-bottom: 5em;\">
${list_html}
            </ul>
${log_html}"

cat /dev/null > "${output_html}"
cat "${html_template}/5check_top.html" >> "${output_html}"
cat "${html_template}/sidebar.html" >> "${output_html}"
cat "${html_template}/5check_content.html" >> "${output_html}"
echo "${html}" >> "${output_html}"
cat "${html_template}/5check_bottom.html" >> "${output_html}"

