#!/usr/bin/env bash
#
# Convert yaml file to csv
# 

# Help message
function usage {
    echo "Usage: $0 -i input.yaml"
    echo "       $0 -i input.yaml [-o input.csv] [-c config]"
    echo "Flags:"
    echo "       -i path and filename to input yaml file"
    echo "       -o OPTIONAL path to output csv file (default: ./input.csv)"
    echo "       -c OPTIONAL path to config file"
    exit 1
}

# Argument flag handling
while getopts "i:o:c:h:" opt
do
    case $opt in
        i)
            input_yaml="$(readlink -f ${OPTARG})"
            ;;
        o)
            input_csv="$(readlink -f ${OPTARG})"
            ;;
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

# Starting yaml flie must be provided
if [[ -z "${input_yaml}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh #-c "${config_file}"

# Set input csv to default if not given
if [[ -z "${input_csv}" ]]
then
    input_csv="$(readlink -f ${log_dir}/_input.csv)"
fi

echo "Converting '${input_yaml}' to '${input_csv}'"
Rscript - <<EOF
library(yaml)

x <- read_yaml("${input_yaml}")[[1]]
out <- lapply(x, function(pkg) {
  pkg_name <- pkg\$package
  pkg_version <- pkg\$version
  pkg_source <- pkg\$source
  if ("organization" %in% names(pkg\$source_info)) {
    pkg_org <- pkg\$source_info\$organization
  } else {
    pkg_org <- ''
  }
  if (pkg_source == "github") {
    if ("repository" %in% names(pkg\$source_info)) {
      pkg_repo <- pkg\$source_info\$repository
    } else {
      pkg_repo <- pkg_name
    }
    if ("branch" %in% names(pkg\$source_info)) {
      pkg_branch <- pkg\$source_info\$branch
    } else {
      pkg_branch <- ''
    }
    if ("commit_sha" %in% names(pkg\$source_info)) {
      pkg_hash <- pkg\$source_info\$commit_sha
    } else {
      pkg_hash <- ''
    }
  } else {
    pkg_repo <- ''
    pkg_branch <- ''
    pkg_hash <- ''
  }
  if ("check" %in% names(pkg\$validnest_steps)) {
    pkg_check <- pkg\$validnest_steps\$check
  } else {
    pkg_check <- TRUE
  }

  data.frame(
    pkg_name = pkg_name,
    pkg_version = pkg_version,
    pkg_source = pkg_source,
    pkg_org = pkg_org,
    pkg_repo = pkg_repo,
    pkg_branch = pkg_branch,
    pkg_hash = pkg_hash,
    pkg_check = pkg_check
  )
})
df <- do.call(rbind, out)

row.names(df) <- NULL
write.csv(df, "${input_csv}")
EOF

echo "Cleaning '${input_csv}' for scripts"
sed -i "s/[\"'‘’]//g" "${input_csv}"
cat "${input_csv}" | tail +2 | sed 's/^[0-9]*,//g' > "${input_csv}.bak" && mv "${input_csv}.bak" "${input_csv}"

