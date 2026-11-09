# tidyverse/dev set
install.packages(c("rlang",
                   "ggplot2",
                   "tidyverse",
                   "dplyr",
                   "rioja",
                   "DT",
                   "pacman",
                   "Bchron",
                   "sf",
                   "terra",
                   "leaflet",
                   "geojsonsf",
                   "readxl",
                   "rgbif",
                   "maps",
                   "geodata",
                   "remotes"))

# neotoma2: the workshop uses the development version from GitHub.
# Once the new release is on CRAN, replace the line below with:
#   install.packages("neotoma2")
remotes::install_github("NeotomaDB/neotoma2", ref = "dev", upgrade = "never")

install.packages("IRkernel")
IRkernel::installspec(user = FALSE,
                      sys_prefix = TRUE)
