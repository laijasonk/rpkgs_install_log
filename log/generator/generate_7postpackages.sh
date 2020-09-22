#!/usr/bin/env bash

# Default paths
log_dir="$(readlink -f ./log)"
output_html="${log_dir}/7postpackages.html"

cat /dev/null > "${output_html}"
cat "${log_dir}/base/7postpackages_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/7postpackages_content.html" >> "${output_html}"
cat "${log_dir}/base/7postpackages_bottom.html" >> "${output_html}"

