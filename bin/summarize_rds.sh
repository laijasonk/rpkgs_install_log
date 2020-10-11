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

rds_file="${lib_dir}/${pkg_name}/tests/unit_testing_results.rds"
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
    status_check_cross <- function(x) {
        ifelse(is.null(x) | x == -1, "", ifelse((is.logical(x) & x == TRUE) | (is.numeric(x) & x == 0), "\\u2714", "\\u2718"))
    }

    library(testthat)
    rds_contents <- as.data.frame(readRDS(file.path('${rds_file}')))
    
    rds_contents\$file_context = paste0(rds_contents\$file, ": ", rds_contents\$context)
    
    output_df = data.frame()
    for (file_context in unique(rds_contents\$file_context)) {
        context_data <- rds_contents[which(rds_contents\$file_context == file_context), ]
        append_df <- data.frame(
            file_context = file_context,
            test = context_data\$test,
            number_of_assertions = context_data\$nb,
            failed = context_data\$failed,
            skipped = context_data\$skipped,
            error = context_data\$error,
            warning = context_data\$warning,
            pass = status_check_cross(context_data\$error == FALSE & context_data\$skipped == FALSE)
        )
        output_df <- rbind(output_df, append_df)
    }
    
    names(output_df) <- unique(rds_contents\$file_context)

    colnames(output_df) <- c("file_context", "test", "number_of_assertions", "failed", "skipped", "error", "warning", "pass")
    row.names(output_df) <- NULL
    write.csv(output_df, '${results_csv}')
EOF

