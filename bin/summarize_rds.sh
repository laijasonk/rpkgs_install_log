#!/usr/bin/env bash

# Help message
function usage {
    echo "Usage: $0 -i pkg_name"
    echo "       $0 -i pkg_name [-o results.csv] [-t $(pwd)]"
    echo "Flags:"
    echo "       -i package name"
    echo "       -o OPTIONAL path to output csv file"
    echo "       -t OPTIONAL path to target directory"
    exit 1
}

# Argument flag handling
while getopts "i:o:t:h" opt
do
    case $opt in
        i) pkg_name="${OPTARG}" ;;
        o) results_csv="$(readlink -f ${OPTARG})" ;;
        t) target_dir="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions to run script
if [[ -z "${pkg_name}" ]]
then
    usage
fi

# Load config variables and convert to absolute pathes
. ./bin/global_config.sh -t "${target_dir}"

# Point to correct output file and reset
if [[ -z "${results_csv}" ]]
then
    results_csv="${log_dir}/rds_${pkg_name}.txt"
fi
cat /dev/null > "${results_csv}"

rds_file="${check_dir}/${pkg_name}.Rcheck/tests/unit_testing_results.rds"
echo "Checking for rds file in '${rds_file}'"
if [[ ! -f "$rds_file" ]]
then
    echo "No rds file found in '${check_dir}/${pkg_name}.Rcheck'"
    echo "WARNING: RDS file does not exist (${rds_file})" > ${results_csv}
    exit 1
fi

# Run R script to convert RDS results to CSV
echo "Converting rds file to '${results_csv}'"
Rscript - <<EOF
    tmp <- as.data.frame(readRDS(file.path('${rds_file}')))
    
    tmp\$file_context = paste0(tmp\$file, ": ", tmp\$context)
    
    x <- lapply(
      unique(tmp\$file_context),
      function(file_context) {
        tmp2 <- tmp[which(tmp\$file_context == file_context), ]
        data.frame(
          test = tmp2\$test,
          number_of_assertions = tmp2\$nb,
          failed = tmp2\$failed,
          skipped = tmp2\$skipped,
          error = tmp2\$error,
          warning = tmp2\$warning,
          pass = status_check_cross(tmp2\$error == FALSE & tmp2\$skipped == FALSE)
        )
      }
    )
    
    names(x) <- unique(tmp\$file_context)
    x
    row.names(x) <- NULL
    write.csv(x, '${results_csv}')
EOF

