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
COPY connecting_to_GBIF.Rmd /home/jovyan/
COPY text.css /home/jovyan/
COPY images/ /home/jovyan/images/

# Only the files the workflows read are copied (not the whole data/ folder).
COPY data/diatom_core_download.RDS /home/jovyan/data/
COPY data/aggregate_slice_download.RDS /home/jovyan/data/
COPY data/aggregate_sites_NorthAmerica.xlsx /home/jovyan/data/
COPY data/diatom_taxontable.csv /home/jovyan/data/
COPY data/gbif_match_three_sites.RDS /home/jovyan/data/
