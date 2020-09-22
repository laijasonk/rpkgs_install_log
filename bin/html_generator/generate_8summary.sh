#!/usr/bin/env bash

# Default paths
log_dir="$(readlink -f ./log)"
output_html="${log_dir}/8summary.html"

cat /dev/null > "${output_html}"
cat "${log_dir}/base/8summary_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/8summary_content.html" >> "${output_html}"
cat "${log_dir}/base/8summary_bottom.html" >> "${output_html}"

