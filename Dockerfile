# docker build --network=host --no-cache --tag testiv .
# docker run --rm -ti --network=host -p 8787:8787 -e PASSWORD=test testiv

FROM rocker/rstudio:3.6.3

# Layer 1
WORKDIR /opt/rlibs/layer1
ADD bin ./bin
COPY full_install.sh examples/layer1.csv ./
RUN ./full_install.sh \
    -i ./layer1.csv \
    -r \
    -o ./

# Layer 2
WORKDIR /opt/rlibs/layer2
ADD bin ./bin
COPY full_install.sh examples/layer2.csv ./
RUN ./full_install.sh \
    -i ./layer2.csv \
    -l /opt/rlibs/layer1/libs \
    -r \
    -o ./

# Layer 3 (artifactory)
WORKDIR /opt/rlibs/layer3_artifactory
ADD bin ./bin
COPY artifactory_build.sh examples/layer3.csv ./
RUN ./artifactory_build.sh \
    -i ./layer3.csv \
    -l /opt/rlibs/layer2/libs:/opt/rlibs/layer1/libs \
    -r \
    -o ./

# Layer 3 (artifactory)
WORKDIR /opt/rlibs/layer3
ADD bin ./bin
COPY artifactory_install.sh ./
RUN cp /opt/rlibs/layer3_artifactory/artifactory.csv ./
RUN ./artifactory_install.sh \
    -i ./artifactory.csv \
    -l /opt/rlibs/layer2/libs:/opt/rlibs/layer1/libs \
    -r \
    -o ./

ENV R_LIBS_SITE=/opt/rlibs/layer3/libs:/opt/rlibs/layer2/libs:/opt/rlibs/layer1/libs
ENV R_LIBS_USER=/opt/rlibs/layer3/libs:/opt/rlibs/layer2/libs:/opt/rlibs/layer1/libs
ENV R_LIBS=/opt/rlibs/layer3/libs:/opt/rlibs/layer2/libs:/opt/rlibs/layer1/libs

# https://stat.ethz.ch/R-manual/R-devel/library/base/html/EnvVar.html

# we need to move this libpath to first place so that .libPaths() in bash, not rstudio, returns
# [1] "/opt/rlibs/one/libs" "/usr/local/lib/R/library"     
# [3] "/usr/local/lib/R/site-library" 
# and not
# [1] "/usr/local/lib/R/site-library" "/usr/local/lib/R/library"     
# [3] "/opt/rlibs/one/libs"  

## only for debugging
#RUN chmod -R 777 /opt/rlibs/one


# docker build --network=host --no-cache --tag testiv .

# explore image with bash
# docker run --rm -ti --network=host testiv /bin/bash

# explore environment with rstudio
# docker run --rm -ti --network=host -p 8787:8787 -e PASSWORD=test testiv 
