#!/usr/bin/env bash

echo "Generating home page"
./log/generator/generate_0home.sh

echo "Generating system information page"
./log/generator/generate_1system.sh

echo "Generating pre-installation packages page"
./log/generator/generate_2prepackages.sh

echo "Generating source preparation page"
./log/generator/generate_3preparation.sh

echo "Generating package installation page"
./log/generator/generate_4install.sh

echo "Generating package check page"
./log/generator/generate_5check.sh

echo "Generating package test page"
./log/generator/generate_6test.sh

echo "Generating post-installation packages page"
./log/generator/generate_7postpackages.sh

echo "Generating summary page"
./log/generator/generate_8summary.sh

