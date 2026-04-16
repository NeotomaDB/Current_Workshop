# tidyverse/dev set
install.packages(c("rlang",
                   "ggplot2",
                   "tidyverse",
                   "dplyr",
                   "rioja",
                   "DT",
                   "pacman",
                   "Bchron",
                   "neotoma2",
                   "sf",
                   "terra",
                   "leaflet",
                   "geojsonsf"))

install.packages("IRkernel")
IRkernel::installspec(user = FALSE,
                      sys_prefix = TRUE)