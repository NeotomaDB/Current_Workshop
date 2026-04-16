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

COPY simple_workflow.Rmd /home/jovyan/
COPY text.css /home/jovyan/
COPY data/ /home/jovyan/data/
COPY images/ /home/jovyan/images/