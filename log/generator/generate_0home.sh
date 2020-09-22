#!/usr/bin/env bash

# Default paths
log_dir="$(readlink -f ./log)"
output_html="${log_dir}/0home.html"
index_html="${log_dir}/index.html"

cat /dev/null > "${output_html}"
cat "${log_dir}/base/0home_top.html" >> "${output_html}"
cat "${log_dir}/base/sidebar.html" >> "${output_html}"
cat "${log_dir}/base/0home_content.html" >> "${output_html}"
cat "${log_dir}/base/0home_bottom.html" >> "${output_html}"

cp "${output_html}" "${index_html}"

