#!/usr/bin/env bash
#
# Run pipeline to build artifactory
#

# Default values
wait_between_packages=false
disable_checks=true
create_rstudio_logs=false
in_rlibs=$(Rscript -e "cat(paste(.libPaths(), collapse=':'))")
in_rbinary="$(which R)"
in_rscript="$(which Rscript)"
target_dir="$(pwd)"
cmd="${0}"

# Help message
function usage {
    echo "Usage: $0 -i artifactory.csv"
    echo "       $0 -i artifactory.csv [-l ${in_rlibs}]"
    echo "       $0 -i artifactory.csv [-b ${in_rbinary}] [-s ${in_rscript}]"
    echo "       $0 -i artifactory.csv [-c] [-r]"
    echo "       $0 -i artifactory.csv [-o ${target_dir}]"
    echo "Flags:"
    echo "       -i input csv containing release packages"
    echo "       -l OPTIONAL libpaths to build on (separated by colon on GNU/Linux)"
    echo "       -b OPTIONAL path to R binary"
    echo "       -s OPTIONAL path to Rscript executable"
    echo "       -c OPTIONAL enable and run checks (disabled by default)"
    echo "       -r OPTIONAL create RStudio web logs (disabled by default)"
    echo "       -o OPTIONAL target directory (default: current directory)"
    exit 1
}

# Argument flag handling
while getopts "i:l:b:s:cro:h" opt
do
    case $opt in
        i) 
            input_csv="$(readlink -f ${OPTARG})" 
            cmd="${cmd} -i ${OPTARG}" ;;
        l) 
            in_rlibs="${OPTARG}"
            cmd="${cmd} -l ${OPTARG}" ;;
        b) 
            in_rbinary="$(readlink -f ${OPTARG})"
            cmd="${cmd} -b ${OPTARG}" ;;
        s) 
            in_rscript="$(readlink -f ${OPTARG})"
            cmd="${cmd} -s ${OPTARG}" ;;
        c)
            disable_checks=false
            cmd="${cmd} -c" ;;
        r)
            create_rstudio_logs=true
            cmd="${cmd} -r" ;;
        o) 
            mkdir -p "${OPTARG}"
            target_dir="$(readlink -f ${OPTARG})"
            cmd="${cmd} -o ${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Conditions for running script
if [[ -z "${input_csv}" ]] || [[ ! -f "${input_csv}" ]]
then
    usage
fi
if [[ -z "${target_dir}" ]]
then
    usage
fi

# Basic message display between each package
function header_msg() {
    echo
    echo "##################################################"
    echo "#"
    echo "# ${1}"
    echo "#"
    echo "##################################################"
    echo
    
    if [ ${wait_between_packages} = true ]
    then
        read -p "" null
    else
        echo
    fi
}

# Get the global variables
. ./bin/global_config.sh -t "${target_dir}"

# Store some of the paths into files
echo "${in_rlibs}" > "${log_dir}"/_rlibs.txt
echo "${in_rbinary}" > "${log_dir}"/_rbinary.txt
echo "${in_rscript}" > "${log_dir}"/_rscript.txt

# Reset the global variables after setting the paths above
. ./bin/global_config.sh -t "${target_dir}"

# Store the current command to a log
echo "CMD: ${cmd}" > ./_stdout.txt
echo >> ./_stdout.txt


##################################################
#
# Initializing system
#
##################################################


# Print the heading
header_msg "Initializing system" | tee -a ./_stdout.txt

# Set the default variables and reset install
./bin/reset_install.sh -t "${target_dir}" | tee -a ./_stdout.txt

# Store stdout into the log directory
stdout_log="${log_dir}/_stdout.txt"
mv ./_stdout.txt "${stdout_log}"

# Prepare the input CSV by stripping extra characters
pkg_csv="${log_dir}/_input.csv"
./bin/strip_csv.sh \
    -1 \
    -i "${input_csv}" \
    -o "${pkg_csv}" | tee -a "${stdout_log}"

# Save a list of the installed R packages
./bin/export_installed_packages.sh -1 -t "${target_dir}" | tee -a "${stdout_log}"

# Track the timestamps
echo "Saving start timestamp" | tee -a "${stdout_log}"
echo "$(date)" > "${log_dir}/_start_timestamp.txt" | tee -a "${stdout_log}"

# Initialize the artifactory CSV with header labels
echo "pkg_name,pkg_version,pkg_source,download_status,build_status,check_status,install_status,test_status" > ./artifactory.csv

# Nicer display
echo | tee -a "${stdout_log}"


##################################################
#
# Per-package instructions
#
##################################################


# Build, install and check every package
while IFS=, read -r pkg_name pkg_version pkg_url pkg_source git_commit
do

    # Print out the heading
    header_msg "${pkg_name}-${pkg_version}" | tee -a "${stdout_log}"

    ./bin/download_and_build.sh \
        -n "${pkg_name}" \
        -v "${pkg_version}" \
        -s "${pkg_source}" \
        -u "${pkg_url}" \
        -c "${git_commit}" \
        -t "${target_dir}" | tee -a "${stdout_log}"

    ./bin/install_source_package.sh \
        -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
        -t "${target_dir}" | tee -a "${stdout_log}"

    # Check package if option flags set
    if [ ${disable_checks} = false ]
    then
        ./bin/check_source_package.sh \
            -i "${build_dir}/${pkg_name}_${pkg_version}.tar.gz" \
            -t "${target_dir}" | tee -a "${stdout_log}"
    else
        echo "Check skipped due to missing -c flag" > "${log_dir}/check_${pkg_name}.txt"
    fi

    # Store the package into the artifactory CSV
    echo "\"${pkg_name}\",\"${pkg_version}\",\"${build_dir}/${pkg_name}_${pkg_version}.tar.gz\",\"build\",\"\"" >> ./artifactory.csv
    
    # Nicer display
    echo | tee -a "${stdout_log}"

done < "${pkg_csv}"


##################################################
#
# Post-build
#
##################################################


# Print out the heading
header_msg "Post-build" | tee -a "${stdout_log}"

# Save another list of the installed R packages
./bin/export_installed_packages.sh -2 -t "${target_dir}" | tee -a "${stdout_log}"

# Save the contents of the artifactory into a log
ls "${build_dir}"/*.tar.gz > "${log_dir}/_artifactory.txt"

# Track the timestamps
echo "Saving end timestamp" | tee -a "${stdout_log}"
echo "$(date)" > "${log_dir}/_end_timestamp.txt" | tee -a "${stdout_log}"

# Nicer display
echo | tee -a "${stdout_log}"


##################################################
#
# Creating HTML log
#
##################################################


# Print out the heading
header_msg "Creating HTML log" | tee -a "${stdout_log}"

# Examine all the logs and summarize the results into a single log file
./bin/summarize_logs.sh -i "${pkg_csv}" -t "${target_dir}" &> /dev/null
echo "pkg_name,pkg_version,pkg_source,download_status,build_status,check_status,install_status,test_status" > ./summary.csv
cat "${log_dir}"/_summary.csv >> ./summary.csv

# Generate all HTML pages
./bin/generate_html.sh -b -t "${target_dir}" | tee -a "${stdout_log}"

# Generate logs for the built-in RStudio Web Server Browser
if [ ${create_rstudio_logs} = true ]
then
    echo "Creating logs for viewing within RStudio's web browser"
    ./bin/create_rstudio_logs.sh -t "${target_dir}"
fi

# Nicer display
echo | tee -a "${stdout_log}"


##################################################
#
# Output
#
##################################################


# Print out the heading
header_msg "Output" | tee -a "${stdout_log}"

# Print out the output files/dirs 
echo "Artifactory: ${build_dir}"
echo "Summary CSV: $(pwd)/summary.csv"
echo "Artifactory CSV: $(pwd)/artifactory.csv"
echo "HTML log: ${html_dir}/index.html"

# Nicer display
echo | tee -a "${stdout_log}"

