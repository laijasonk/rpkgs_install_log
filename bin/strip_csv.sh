#!/usr/bin/env bash
#
# Strips CSV for scripts (assumes header)
#

# Help message
function usage {
    echo "Usage: $0 -i input.csv"
    echo "       $0 -i input.csv -o output.csv"
    echo "       $0 -i input.csv [-1] -o output.csv"
    echo "Flags:"
    echo "       -i path to input csv"
    echo "       -o OPTIONAL path to output csv (default: ./input.csv_stripped)"
    echo "       -1 OPTIONAL strip header from csv"
    exit 1
}

# Argument flag handling
while getopts "i:o:1h" opt
do
    case $opt in
        i)
            input_csv="$(readlink -f ${OPTARG})"
            ;;
        o)
            output_csv="${OPTARG}"
            ;;
        1)
            header=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Conditions for running script
if [[ -z "${input_csv}" ]]
then
    usage
fi
if [[ -z "${output_csv}" ]]
then
    output_csv="${input_csv}_stripped"
fi

# Clean csv file remove extra spaces and quote-like characters
cat "${input_csv}" \
    | sed -e "s/[\"'‘] *, *[\"'’]/,/g" \
        -e "s/[\"'‘’]//g" \
        -e "s/^[0-9]*,//g" \
    > "${input_csv}.tmp"

# Remove header if specified
if [[ "${header}" -eq 1 ]]
then
    tail +2 "${input_csv}".tmp > "${output_csv}"
else
    mv "${input_csv}".tmp "${output_csv}"
fi

echo "Stripped ${input_csv} for scripts"
echo "Saved stripped csv to ${output_csv}"

