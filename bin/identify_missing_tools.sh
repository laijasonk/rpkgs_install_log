#!/usr/bin/env bash
#
# Find missing tools and install if missing
#

# Default values (TODO: add option flags)
external_repo="http://cran.r-project.org"
lib_dir="$(readlink -f ./libs-r)"
cran_dir="$(readlink -f ./libs-cran)"
log_dir="$(readlink -f ./log)"
tool_log="${log_dir}/missing_tool_install.log"

# Create directory if it doesn't exist
mkdir -p "${lib_dir}" "${cran_dir}"

# Set lib paths
if [[ "$R_LIBS_USER" ]]
then
    export R_LIBS_USER="${lib_dir}:${cran_dir}:${R_LIBS_USER}"
else
    export R_LIBS_USER="${lib_dir}:${cran_dir}"
fi

# Rscript to check if package installed (if not, then install)
function check_and_install() {
    pkg_name="${1}"
    echo "Checking ${pkg_name}"
    Rscript -e "require(\"${pkg_name}\")"
    Rscript -e "if (!require(\"${pkg_name}\")) install.packages(\"${pkg_name}\", repos=\"${external_repo}\", lib=\"${cran_dir}\")" %> /dev/null
}

# Run BASH function from above
check_and_install "devtools"
echo
check_and_install "roxygen2"
echo
check_and_install "knitr"
echo
check_and_install "rmarkdown"
echo

