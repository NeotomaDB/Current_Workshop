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
COPY complex_workflow.Rmd /home/jovyan/
COPY maps_neotomaWorkshop.Rmd /home/jovyan/
COPY text.css /home/jovyan/
COPY images/ /home/jovyan/images/

# Only the files the workflows read are copied (not the whole data/ folder).
COPY data/diatom_core_download.RDS /home/jovyan/data/
COPY data/gbif_match_barnegat.RDS /home/jovyan/data/

# maps_neotomaWorkshop.Rmd
COPY data/diatomSurfaceSamples_NorthAmerica.rds /home/jovyan/data/
COPY data/diatom_NorthAmerica.rds /home/jovyan/data/
COPY data/waterChem_NorthAmerica.rds /home/jovyan/data/
COPY data/aggData_DiatomSamples.rds /home/jovyan/data/
COPY data/aggData_WaterChem.rds /home/jovyan/data/
COPY data/maps_climate_values.csv /home/jovyan/data/
# The file name has spaces, so the JSON form of COPY is needed.
COPY ["data/Aggregate Datasets - Diatoms - Neotoma - 6 Jan2024.xlsx", "/home/jovyan/data/"]
