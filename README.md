# Install and IV

Bash scripts to install R packages based on R environments described with in yaml files.

## Usage

```
Usage: ./full_install.sh -i input.csv
       ./full_install.sh -i input.csv [-l /opt/bee_tools/R/3.6.1/lib64/R/library_sec:/opt/bee_tools/R/3.6.1/lib64/R/library]
       ./full_install.sh -i input.csv [-b /usr/bin/R] [-s /usr/bin/Rscript]
       ./full_install.sh -i input.csv [-c] [-t]
       ./full_install.sh -i input.csv [-o ./]
Flags: 
       -i input csv containing release packages
       -l OPTIONAL libpaths to build on (separated by colon on GNU/Linux)
       -b OPTIONAL path to R binary
       -s OPTIONAL path to Rscript executable
       -c OPTIONAL enable and run checks (disabled by default)
       -t OPTIONAL enable and run unit tests (disabled by default)
       -o OPTIONAL target directory (default: current directory)
```

## Examples

### Example: Full install from scratch

This example lists out all the option flags, but many of the flags are optional. Run `./full_install.sh -h` to see the default values.

```
./full_install.sh \
    -i ./examples/NEST_363_release_subset.csv \
    -l /opt/bee_tools/R/3.6.1/lib64/R/library_sec:/opt/bee_tools/R/3.6.1/lib64/R/library \
    -b /usr/bin/R \
    -s /usr/bin/Rscript \
    -c -t \
    -o ./output
```

### Example: Build and install from an artifactory

Build an artifactory from an input CSV file into a target directory with checks, then install that artifactory into a separate a build directory with unit tests.

```
# Build an artifactory
./artifactory_build.sh \
    -i ./examples/NEST_363_release_subset.csv \
    -o ./example_build/ \
    -c

# Confirm contents of artifactory
ls ./example_build/build

# Confirm creation of new artifactory CSV
cat ./artifactory.csv

# Rename summary.csv to avoid overwriting
mv ./summary.csv ./example_build_summary.csv

# Install from artifactory
./artifactory_install.sh \
    -i ./artifactory.csv \
    -o ./example_install/ \
    -t

# Rename summary.csv for clarity
mv ./summary.csv ./example_install_summary.csv
```

### Example: Install 3 layers into a single rlibs path

Install from three separate CSV files into the same R library path. In order to track the log for each install, the `./log` directory is renamed before running the next command.

```
./full_install.sh -i ./examples/layer1.csv
mv ./log ./layer1_log
mv ./summary.csv ./layer1_summary.csv

./full_install.sh -i ./examples/layer2.csv
mv ./log ./layer2_log
mv ./summary.csv ./layer2_summary.csv

./full_install.sh -i ./examples/layer3.csv
mv ./log ./layer3_log
mv ./summary.csv ./layer3_summary.csv
```

### Example: Install 3 layers into separate directories

Install from three CSV files into three rlibs paths. The target directory is different for every layer. Since layer2 depends on layer1 and layer3 depends on layer2, the libpaths must be specified accordingly.

```
./full_install.sh \
    -i ./examples/layer1.csv \
    -o ./layer1 
mv ./summary.csv ./layer1_summary.csv

./full_install.sh \
    -i ./examples/layer2.csv \
    -l /path/to/layer1/libs \
    -o ./layer2 
mv ./summary.csv ./layer2_summary.csv

./full_install.sh \
    -i ./examples/layer2.csv \
    -l /path/to/layer2/libs:/path/to/layer1/libs \
    -o ./layer3 
mv ./summary.csv ./layer2_summary.csv
```

