[![language-EN](https://img.shields.io/badge/language-EN-red)](README.md) [![language](https://img.shields.io/badge/language-ES-red)](README.es.md) [![language-RU](https://img.shields.io/badge/language-RU-red)](README.ru.md)
[![language-JP](https://img.shields.io/badge/language-JP-red)](README.jp.md)

[![lifecycle](https://img.shields.io/badge/lifecycle-active-orange.svg)](https://www.tidyverse.org/lifecycle/#active)
[![NSF-1948926](https://img.shields.io/badge/NSF-1948926-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1948926)

# Neotoma Current R Workshop

A repository to host interactive R workshops. This repository will always be set up for the most recent/current Neotoma Workshop. All past workshops will be archived in the [Neotoma Workshops](https://github.com/NeotomaDB/Workshops) repository.

This repository is built with the structure required to serve the content through an interactive, online RStudio session using Binder (and Docker). Clicking the Binder link will open RStudio in the user's browser.

**Currently, this repo hosts the Workshop to be delivered in Aarhus about Species Distribution Modelling with pollen data.**

To access the content for this Workshop, click the badge below:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NeotomaDB/Current_Workshop/main?urlpath=rstudio)

## Contributors

This is an open project and contributions are welcome from any individual.  All contributors to this project are bound by a [code of conduct](CODE_OF_CONDUCT.md).  Please review and follow this code of conduct as part of your contribution.

* [![orcid](https://img.shields.io/badge/orcid-0000--0002--7926--4935-brightgreen.svg)](https://orcid.org/0000-0002-7926-4935) [Socorro Dominguez Vidana](https://sedv8808.github.io/)

* [![orcid](https://img.shields.io/badge/orcid-0000--0002--2700--4605-brightgreen.svg)](https://orcid.org/0000-0002-2700-4605) [Simon Goring](http://goring.org)

* [![orcid](https://img.shields.io/badge/orcid-0000--0002--3693--5946-brightgreen.svg)](https://orcid.org/0000-0002-3693-5946) [Nora Schlenker](https://geography.wisc.edu/staff/schlenker-nora/)

### Translations

* Russian: [Arsenii Galimov](https://ipae.uran.ru/Galimov_AT)
* Spanish: [Deborah V. Espinosa-Martínez](https://orcid.org/0000-0002-3848-8094)
* Japanese: [Socorro Dominguez Vidana](https://ht-data.com/about.html)

## How to use this repository

This repository contains two different R workflows, a complex workflow that shows how to manage and modify chronologies with the R package, and a simple workflow that shows how to access data and perform relatively simple analysis. These workflows may be modified for content (e.g., focusing on different dataset types or geospatial contexts).

Users may clone this workshop and modify the content, but be aware that the Binder links are specific to this repository, and must be modified through the users' own Binder setup.

* `apt.txt` defines a set of packages required by Binder/Docker to enable the spatial tools in the `neotoma2` R package.
* `install.R` defines the R packages that are to be loaded by the Binder environment at runtime.
