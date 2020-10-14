FROM rocker/rstudio:3.6.3

WORKDIR /opt/rlibs/one

ADD bin ./bin
COPY full_install.sh examples/NEST_363_release_subset.csv ./

RUN ./full_install.sh \
    -i ./NEST_363_release_subset.csv

# https://stat.ethz.ch/R-manual/R-devel/library/base/html/EnvVar.html

# we need to move this libpath to first place so that .libPaths() in bash, not rstudio, returns
# [1] "/opt/rlibs/one/libs" "/usr/local/lib/R/library"     
# [3] "/usr/local/lib/R/site-library" 
# and not
# [1] "/usr/local/lib/R/site-library" "/usr/local/lib/R/library"     
# [3] "/opt/rlibs/one/libs"  


ENV R_LIBS_USER=/opt/rlibs/one/libs

# only for debugging
RUN chmod -R 777 /opt/rlibs/one


# docker build --network=host --no-cache --tag testiv .

# explore image with bash
# docker run --rm -ti --network=host testiv /bin/bash

# explore environment with rstudio
# docker run --rm -ti --network=host -p 8787:8787 -e PASSWORD=test testiv 
