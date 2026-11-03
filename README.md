[![lifecycle](https://img.shields.io/badge/lifecycle-active-green.svg)]

[![NSF-1948926](https://img.shields.io/badge/NSF-1948926-blue.svg)](https://nsf.gov/awardsearch/showAward?AWD_ID=1948926)

# Neotoma Current R Workshop

[Simple Workflow: North American Diatoms](https://open.neotomadb.org/Current_Workshop/simple_workflow.html) | [Connecting to GBIF](https://open.neotomadb.org/Current_Workshop/connecting_to_GBIF.html)

A repository to host the interactive `neotoma2` R workshops. This repository will always be set up for the most recent/current Neotoma Workshop. All past workshops will be archived in the [Neotoma Workshops](https://github.com/NeotomaDB/Workshops) repository.

This repository is built with the structure required to serve the content through an interactive, online RStudio session using Binder. Clicking the Binder link will open RStudio in the user's browser.

**Currently, this repo hosts the Neotoma Diatom Workshop to be delivered at Drexel University, Philadelphia, Pennsylvania, USA, on November 10-12, 2026.** The R sessions are on **November 10 and 11**. Because the workshop is held in the United States, the examples focus on diatoms in the USA and the wider North American region.

The workshop material is:

* `simple_workflow.Rmd`: *A Simple Workflow: North American Diatoms*. Search for diatom and water chemistry sites, compare them, download a diatom record, draw a stratigraphic diagram, and start from a spreadsheet of site IDs (an "aggregate dataset").
* `connecting_to_GBIF.Rmd`: *Connecting to GBIF*. Connect to the free [GBIF](https://www.gbif.org) API with the `rgbif` package and compare Neotoma diatom records with GBIF diatom occurrences.

To access the content for this Workshop, click the badge below:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/NeotomaDB/Current_Workshop/main?urlpath=rstudio)

## Contributors

This is an open project and contributions are welcome from any individual.  All contributors to this project are bound by a [code of conduct](CODE_OF_CONDUCT.md).  Please review and follow this code of conduct as part of your contribution.

* [![orcid](https://img.shields.io/badge/orcid-0000--0002--7926--4935-brightgreen.svg)](https://orcid.org/0000-0002-7926-4935) [Socorro Dominguez Vidana](https://ht-data.com/)

* [![orcid](https://img.shields.io/badge/orcid--brightgreen.svg)](https://orcid.org/) [Nick Hoffman]()

* [![orcid](https://img.shields.io/badge/orcid-0000--0002--2700--4605-brightgreen.svg)](https://orcid.org/0000-0002-2700-4605) [Simon Goring](http://goring.org)

* Zoe Kerrich, Drexel University (Academy of Natural Sciences): the diatom mapping workflow, the North America polygon and the aggregate-dataset inventory that this workshop material is adapted from.

## How to use this repository

This repository contains a simple workflow that shows how to access data and perform relatively simple analysis. These workflows may be modified for content (e.g., focusing on different dataset types or geospatial contexts).

Users may clone this workshop and modify the content, but be aware that the Binder links are specific to this repository, and must be modified through the users' own Binder setup.

* `Dockerfile` defines the Binder/Docker image. It copies only the files the two workflows read.
* `install.r` defines the R packages that are installed in the Binder environment. The workshop uses the development version of `neotoma2` from GitHub (`NeotomaDB/neotoma2`, branch `dev`). After the new release reaches CRAN, `install.r` can go back to `install.packages("neotoma2")`.
* `data/` holds pre-downloaded Neotoma and GBIF results, so the workflows do not depend on live API calls during the workshop. `data/aggregate_sites_NorthAmerica.xlsx` lists the Neotoma site IDs of the North American diatom aggregate dataset (derived from the Drexel aggregate-dataset inventory).

To run the workflows locally, install the packages listed in `install.r` and open the `.Rmd` files in RStudio.
