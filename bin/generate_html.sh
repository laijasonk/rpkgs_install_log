#!/usr/bin/env bash

echo "Generating home page"
./bin/html_generator/generate_0home.sh

echo "Generating system information page"
./bin/html_generator/generate_1system.sh

echo "Generating pre-installation packages page"
./bin/html_generator/generate_2prepackages.sh

echo "Generating source preparation page"
./bin/html_generator/generate_3preparation.sh

echo "Generating package installation page"
./bin/html_generator/generate_4install.sh

echo "Generating package check page"
./bin/html_generator/generate_5check.sh

echo "Generating package test page"
./bin/html_generator/generate_6test.sh

echo "Generating post-installation packages page"
./bin/html_generator/generate_7postpackages.sh

echo "Generating summary page"
./bin/html_generator/generate_8summary.sh

