FROM rocker/binder

# RUN apt-get update && apt-get install -y \
#     libudunits2-dev \
#     libgdal-dev \
#     libgeos-dev \
#     libproj-dev \
#     libglpk-dev \
#     && rm -rf /var/lib/apt/lists/*

COPY install.r install.r
RUN Rscript install.r

COPY simple_workflow.Rmd /home/rstudio/
COPY data/ /home/rstudio/data/
COPY images/ /home/rstudio/images/