FROM continuumio/miniconda3:24.9.2-0
LABEL maintainer="michael.schneider@cruk.cam.ac.uk"
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ARG PATH="/opt/conda/bin:${PATH}"

ADD spec-file.txt /tmp/spec-file.txt
RUN conda create -n conda_runtime python=3.6 && \
    conda install mamba -n base -c conda-forge
RUN conda install --name conda_runtime --file /tmp/spec-file.txt && conda clean -afy

RUN conda install --name conda_runtime -c bioconda picard=2.26.11 -y && conda clean -afy 

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "conda_runtime", "/bin/bash", "-c"]

RUN Rscript -e "library(devtools); library(withr); \
                withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
                devtools::install_github(\"asntech/QDNAseq.hg38@v1.1.0\", dep = FALSE));"

RUN Rscript -e "library(devtools); library(withr); \
        withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
        install_version(\"changepoint.np\", version=\"1.0.3\", repos=\"https://cloud.r-project.org\")); \
        withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
        install_version(\"gfpop\",version=\"1.0.3\", repos=\"https://cloud.r-project.org\")); \
        withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
        install_version(\"RcppArmadillo\", version=\"0.12.6.6.0\", repos=\"https://cloud.r-project.org\")); \
        withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
        install_version(\"trend\",version=\"1.1.4\", repos=\"https://cloud.r-project.org\")); \
        withr::with_libpaths(new = \"/opt/conda/envs/conda_runtime/lib/R/library\", \
        install_version(\"infotheo\",version=\"1.2.0\", repos=\"https://cloud.r-project.org\"));"

# add scAbsolute source
ADD R /opt/scAbsolute/R
ADD data /opt/scAbsolute/data
ADD scripts /opt/scAbsolute/scripts
ADD LICENSE /opt/scAbsolute/
ADD README.md /opt/scAbsolute/

# Compile PELT
RUN cd /opt/scAbsolute/data/changepoint && R CMD SHLIB cost_general_functions.c PELT_one_func_minseglen.c -o PELT.so
