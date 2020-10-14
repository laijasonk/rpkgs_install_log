FROM rocker/rstudio:3.6.3

WORKDIR /opt/rlibs/one

ADD bin ./bin
COPY full_install.sh examples/NEST_363_release_subset.csv ./

RUN ./full_install.sh \
    -i ./NEST_363_release_subset.csv \
    -b /usr/bin/R \
    -s /usr/bin/Rscript 


# only for debugging
RUN chmod -R 777 /opt/rlibs/one


# docker build --network=host --no-cache --tag testiv .

# explore image with bash
# docker run --rm -ti --network=host testiv /bin/bash

# explore environment with rstudio
# docker run --rm -ti --network=host -p 8787:8787 -e PASSWORD=test testiv 
