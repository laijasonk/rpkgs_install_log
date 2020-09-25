#!/usr/bin/env bash
#
# Find missing tools and install if missing
#

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

# Log files
tool_log="${log_dir}/missing_tool_install.txt"

# Rscript to check if package installed (if not, then install)
function check_and_install() {
    pkg_name="${1}"
    echo "Checking '${pkg_name}'"
    Rscript -e "require(\"${pkg_name}\")"
    Rscript -e "if (!require(\"${pkg_name}\")) install.packages(\"${pkg_name}\", repos=\"${external_repo}\", lib=\"${cran_dir}\")" %> /dev/null
}

# Run BASH function from above
check_and_install "testthat"
echo
check_and_install "yaml"
echo

#check_and_install "testthat"
#echo
#check_and_install "devtools"
#echo
#check_and_install "roxygen2"
#echo
#check_and_install "knitr"
#echo
#check_and_install "rmarkdown"
#echo
#check_and_install "covr"
#echo

