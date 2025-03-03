---
title: "A Simple Workflow -- For Speleothems"
author:
  - name: "Nora Schlenker"
    institute: [uwiscgeog]
    correspondence: false
    email: nschlenker@wisc.edu
    orcid_id: 0000-0002-3693-5946
  - name: "Simon Goring"
    institute: [uwiscgeog,uwiscdsi]
    correspondence: true
    email: goring@wisc.edu
    orcid_id: 0000-0002-2700-4605
  - name: "Socorro Dominguez Vidaña"
    institute: [htdata, uwiscgeog]
    correspondence: false
    email: s.dominguez@ht-data.com
    orcid_id: 0000-0002-7926-4935
institute:
  - htdata:
    name: "HT Data"
  - uwiscgeog:
    name: "University of Wisconsin -- Madison: Department of Geography"
  - uwiscdsi:
    name: "University of Wisconsin -- Data Science Institute"
date: "2024-05-31"
output:
  html_document:
    code_folding: show
    fig_caption: yes
    keep_md: yes
    self_contained: yes
    theme: readable
    toc: yes
    toc_float: yes
    css: "text.css"
  pdf_document:
    pandoc_args: "-V geometry:vmargin=1in -V geometry:hmargin=1in"
csl: 'https://bit.ly/3khj0ZL'
---



## Introduction

This document is intended to act as a primer for the use of the new Neotoma R package, `neotoma2` and is the companion to the [*Introduction to Neotoma* presentation](https://docs.google.com/presentation/d/1Fwp5yMAvIdgYpiC04xhgV7OQZ-olZIcUiGnLfyLPUt4/edit?usp=sharing). Some users may be working with this document as part of a workshop for which there is a Binder instance. The Binder instance will run RStudio in your browser, with all the required packages installed.

If you are using this workflow on its own, or want to use the package directly, [the `neotoma2` package](https://github.com/NeotomaDB/neotoma2) is available on CRAN by running:

```r
install.packages('neotoma2')
library(neotoma2)
```

Your version should be at or above 0.0.1.

This workshop will also require other packages. To maintain the flow of this document we've placed instructions at the end of the document in the section labelled "[Installing packages on your own](#localinstall)". Please install these packages, and make sure they are at the lastest version.

## Learning Goals

In this tutorial you will learn how to:

1. [Site Searches](#3-site-searches): Search for sites using site names and geographic parameters.
2. [Filter Results](#33-filter-records-tabset): Filter results using temporal and spatial parameters.
3. [Explore Data](#34-pulling-in-sample-data): Obtain sample information for the selected datasets.
4. [Visualize Data](#4-simple-analytics): Perform basic Stratigraphic Plotting

## Background

### Getting Help with Neotoma

If you're planning on working with Neotoma, please join us on [Slack](https://join.slack.com/t/neotomadb/shared_invite/zt-cvsv53ep-wjGeCTkq7IhP6eUNA9NxYQ) where we manage a channel specifically for questions about the R package (the *#it_r* channel, or *#it_r_es* for R help in Spanish and *#it_r_jp* in Japanese). You may also wish to join the Neotoma community through our Google Groups mailing lists; please [see the information on our website](https://www.neotomadb.org/about/join-the-neotoma-community) to be added.

### Understanding Data Structures in Neotoma

Data in the Neotoma database itself is structured as a set of linked relationships to express different elements of paleoecological analysis:

* space and time
  * Where is a sample located in latitude and longitude?
  * Where is a sample along a depth profile?
  * What is the estimated age of that sample?
  * What is the recorded age of elements within or adjacent to the sample?
* observations
  * What is being counted or measured?
  * What units are being used?
  * Who observed it?
* scientific methods
  * What statistical model was used to calculate age?
  * What uncertainty terms are used in describing an observation?
* conceptual data models
  * How do observations in one sample relate to other samples within the same collection?
  * How does an observation of a fossil relate to extant or extinct relatives?

These relationships can be complex because paleoecology is a broad and evolving discipline. As such, the database itself is highly structured, and normalized, to allow new relationships and facts to be added, while maintaining a stable central data model. If you want to better understand concepts within the database, you can read the [Neotoma Database Manual](https://open.neotomadb.org/manual), or take a look at [the database schema itself](https://open.neotomadb.org/dbschema).

In this workshop we want to highlight two key structural concepts:
  
  1. The way data is structured conceptually within Neotoma (Sites, Collection Units and Datasets).
  2. The way that this structure is adapted within the `neotoma2` R package.

#### Data Structure in the Neotoma Database

![**Figure**. *The structure of sites, collection units, samples, and datasets within Neotoma. A site contains one or more collection units. Chronologies are associated with collection units. Samples with data of a common type (pollen, diatoms, vertebrate fauna) are assigned to a dataset.*](images/site_collunit_dataset_rev.png){width=50%}  
  
Data in Neotoma is associated with **sites** -- specific locations with latitude and longitude coordinates.

Within a **site**, there may be one or more [**collection units**](https://open.neotomadb.org/manual/dataset-collection-related-tables-1.html#CollectionUnits) -- locations at which samples are physically collected within the site:

* an archaeological **site** may have one or more **collection units**, pits within a broader dig site
* a pollen sampling **site** on a lake may have multiple **collection units** -- core sites within the lake basin.
* A bog sample **site** may have multiple **collection units** -- a transect of surface samples within the bog.

Collection units may have higher resolution GPS locations than the site location, but are considered to be part of the broader site.

Data within a **collection unit** is collected at various [**analysis units**](https://open.neotomadb.org/manual/sample-related-tables-1.html#AnalysisUnits).

* All sediment at 10cm depth in the depth profile of a cutbank (the collection unit) along an oxbow lake (the site) is one analysis unit.
* All material in a single surface sample (the collection unit) from a bog (the site) is an analysis unit.
* All fossil remains in a buried layer from a bone pile (the collection unit) in a cave (the site) is an analysis unit.

Any data sampled within an analysis unit is grouped by the dataset type (charcoal, diatom, dinoflagellate, etc.) and aggregated into a [**sample**](https://open.neotomadb.org/manual/sample-related-tables-1.html#Samples). The set of samples for a collection unit of a particular dataset type is then assigned to a [**dataset**](https://open.neotomadb.org/manual/dataset-collection-related-tables-1.html#Datasets).

* A sample would be all diatoms (the dataset type) extracted from sediment at 12cm (the analysis unit) in a core (the collection unit) obtained from a lake (the site).
* A sample would be the record of a single mammoth bone (sample and analysis unit, dataset type is vertebrate fauna) embeded in a riverbank (here the site, and collection unit).

#### Data Structures in `neotoma2` {#222-data-structures-in-neotoma2}

![**Figure**. *Neotoma R Package UML diagram. Each box represents a data class within the package. Individual boxes show the class object, its name, its properties, and functions that can be applied to those objects. For example, a `sites` object has a property `sites`, that is a list. The function `plotLeaflet()` can be used on a `sites` object.*](images/neotomaUML_as.svg)  

If we look at the [UML diagram](https://en.wikipedia.org/wiki/Unified_Modeling_Language) for the objects in the `neotoma2` R package we can see that the data structure generally mimics the structure within the database itself.  As we will see in the [Site Searches section](#3-site-searches), we can search for these objects, and begin to manipulate them (in the [Simple Analysis section](#4-simple-analytics)).

It is important to note: *within the `neotoma2` R package, most objects are `sites` objects, they just contain more or less data*.  There are a set of functions that can operate on `sites`.  As we add to `sites` objects, using `get_datasets()` or `get_downloads()`, we are able to use more of these helper functions.

## Site Searches

### `get_sites()`

There are several ways to find sites in `neotoma2`, but we think of `sites` as being spatial objects primarily. They have names, locations, and are found within the context of geopolitical units, but within the API and the package, the site itself does not have associated information about taxa, dataset types or ages.  It is simply the container into which we add that information.  So, when we search for sites we can search by:

| Parameter | Description |
| --------- | ----------- |
| sitename | A valid site name (case insensitive) using `%` as a wildcard. |
| siteid | A unique numeric site id from the Neotoma Database |
| loc | A bounding box vector, geoJSON or WKT string. |
| altmin | Lower altitude bound for sites. |
| altmax | Upper altitude bound for site locations. |
| database | The constituent database from which the records are pulled. |
| datasettype | The kind of dataset (see `get_tables(datasettypes)`) |
| datasetid | Unique numeric dataset identifier in Neotoma |
| doi | A valid dataset DOI in Neotoma |
| gpid | A unique numeric identifier, or text string identifying a geopolitical unit in Neotoma |
| keywords | Unique sample keywords for records in Neotoma. |
| contacts | A name or numeric id for individuals associuated with sites. |
| taxa | Unique numeric identifiers or taxon names associated with sites. |

All sites in Neotoma contain one or more datasets. It's worth noting that the results of these search parameters may be slightly unexpected. For example, searching for sites by sitename, latitude, or altitude will return all of the datasets for the particular site. Searching for terms such as datasettype, datasetid or taxa will return the site, but the only datasets returned will be those matching the dataset-specific search terms. We'll see this later.

#### Site names: `sitename="%ø%"` {.tabset}

We may know exactly what site we're looking for ("Lake Solsø"), or have an approximate guess for the site name (for example, we know it's something like "Solsø", but we're not sure how it was entered specifically), or we may want to search all sites that have a specific term, for example, *ø*.

We use the general format: `get_sites(sitename="%ø%")` for searching by name.

PostgreSQL (and the API) uses the percent sign as a wildcard.  So `"%ø%"` would pick up ["Lake Solsø"](https://data.neotomadb.org/4445) for us (and picks up "Isbenttjønn" and "Lake Flåfattjønna").  Note that the search query is also case insensitive.

##### Code


```r
denmark_sites <- neotoma2::get_sites(sitename = "%ø%")
plotLeaflet(denmark_sites)
```

##### Result


```{=html}
<div class="leaflet html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-63211a338a5cddfd56e2" style="width:672px;height:480px;"></div>
<script type="application/json" data-for="htmlwidget-63211a338a5cddfd56e2">{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addProviderTiles","args":["Stamen.TerrainBackground",null,null,{"errorTileUrl":"","noWrap":false,"detectRetina":false}]},{"method":"addTiles","args":["https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":1,"detectRetina":false,"attribution":"&copy; <a href=\"https://openstreetmap.org\">OpenStreetMap<\/a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA<\/a>"}]},{"method":"addCircleMarkers","args":[[64.910744,56.12833,82.333,62.331198,60.71667,61.41667,59.81667,61.5625,68.44417,59.625946,59.34349,59.669884,58.537336,59.76475,79.74,62.46667,62.38333,62.32361,62.4,79.74,78.1,78.2,78.2,78.2,78.2],[11.6594,8.613126,-23.846,10.397466,7,8.66667,6,10.26778,18.07167,7.986352,7.30483,7.540184,7.73367,7.433998,10.80421,9.61667,9.66667,9.73833,9.68333,10.80421,14.1,15.75,15.75,15.75,15.75],10,null,null,{"interactive":true,"draggable":false,"keyboard":true,"title":"","alt":"","zIndexOffset":0,"opacity":1,"riseOnHover":true,"riseOffset":250,"stroke":true,"color":"#03F","weight":5,"opacity.1":0.5,"fill":true,"fillColor":"#03F","fillOpacity":0.2},{"showCoverageOnHover":true,"zoomToBoundsOnClick":true,"spiderfyOnMaxZoom":true,"removeOutsideVisibleBounds":true,"spiderLegPolylineOptions":{"weight":1.5,"color":"#222","opacity":0.5},"freezeAtZoom":false},null,["<b>Blåvasstjønn<\/b><br><b>Description:<\/b> Lake with surrounding fen. Physiography: underlying bedrock (Amphibole/Gneiss). Surrounding vegetation: mixed pine/spruce forest/ombrogenic mire.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3022>Explorer Link<\/a>","<b>Lake Solsø<\/b><br><b>Description:<\/b> Strongly drained lake, now mostly fen. Physiography: almost flat landscape, 30-90 asl heights. Surrounding vegetation: dry-moist pasture, fertilized.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3432>Explorer Link<\/a>","<b>Kap København<\/b><br><b>Description:<\/b> The Kap København Formation consists of shallow marine deposits containing terrestrially-derived organic materials. Outcrops occur about 230 m above Mudderbugt as a result of glacioisostatic and eustatic sea-level changes. <br><a href=http://apps.neotomadb.org/explorer/?siteids=10066>Explorer Link<\/a>","<b>Lake Flåfattjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Plateau. Surrounding vegetation: Birch forest. Vegetation formation: Alpine zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13383>Explorer Link<\/a>","<b>Trettetjørn<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Plateau. Surrounding vegetation: Betula pubescens and scattered birch. Vegetation formation: Low-alpine vegetation zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13390>Explorer Link<\/a>","<b>Brurskardtjørni<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Montain. Surrounding vegetation: Salix and Betula shrubs, open grassland. Vegetation formation: Low alpine vegetation.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13391>Explorer Link<\/a>","<b>Vestre Øykjamyrtjørn<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Fjord. Surrounding vegetation: Just above tree-line Betula alnus. Vegetation formation: Boreonemoral zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13392>Explorer Link<\/a>","<b>Måsåtjørnet<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Mid-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26129>Explorer Link<\/a>","<b>Bjørnfjelltjørn<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: Above Betula pub. forest limit. Vegetation formation: Low Alpine.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26169>Explorer Link<\/a>","<b>Øygardstjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Middle-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26212>Explorer Link<\/a>","<b>Lisletjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Middle-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26213>Explorer Link<\/a>","<b>Flotatjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Shrubs. Vegetation formation: Northern-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26214>Explorer Link<\/a>","<b>Grostjørna<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Southern-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26217>Explorer Link<\/a>","<b>Isbenttjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Shrubs and herbs. Vegetation formation: North-Boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26221>Explorer Link<\/a>","<b>Søre Salatberget<\/b><br><b>Description:<\/b> steep, rocky bird cliff<br><a href=http://apps.neotomadb.org/explorer/?siteids=28135>Explorer Link<\/a>","<b>Lake Ristjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28411>Explorer Link<\/a>","<b>Lake Topptjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28412>Explorer Link<\/a>","<b>Lake Heimtjønna<\/b><br><b>Description:<\/b> Lake. Physiography: depression. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28431>Explorer Link<\/a>","<b>Lake Store Finnsjøen<\/b><br><b>Description:<\/b> Lake. Physiography: depression in Mt Finnshø. Surrounding vegetation: lichen dominated dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28440>Explorer Link<\/a>","<b>Søre Salatberget<\/b><br><b>Description:<\/b> NA<br><a href=http://apps.neotomadb.org/explorer/?siteids=28575>Explorer Link<\/a>","<b>Bjørndalen<\/b><br><b>Description:<\/b> Erosion material near stream<br><a href=http://apps.neotomadb.org/explorer/?siteids=28578>Explorer Link<\/a>","<b>Lindholmhøgda 1<\/b><br><b>Description:<\/b> Rather dry closed moss tundra<br><a href=http://apps.neotomadb.org/explorer/?siteids=28648>Explorer Link<\/a>","<b>Lindholmhøgda 2<\/b><br><b>Description:<\/b> Rather moist closed moss tundra<br><a href=http://apps.neotomadb.org/explorer/?siteids=28652>Explorer Link<\/a>","<b>Lindholmhøgda 3<\/b><br><b>Description:<\/b> Wet peaty gully<br><a href=http://apps.neotomadb.org/explorer/?siteids=28653>Explorer Link<\/a>","<b>Lindholmhøgda 4<\/b><br><b>Description:<\/b> Very wet shallow peaty gullet<br><a href=http://apps.neotomadb.org/explorer/?siteids=28654>Explorer Link<\/a>"],null,null,{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]}],"limits":{"lat":[56.12833,82.333],"lng":[-23.846,18.07167]}},"evals":[],"jsHooks":[]}</script>
```

#### Location: `loc=c()` {.tabset}

The original `neotoma` package used a bounding box for locations, structured as a vector of latitude and longitude values: `c(xmin, ymin, xmax, ymax)`.  The `neotoma2` R package supports both this simple bounding box, but also more complex spatial objects, using the [`sf` package](https://r-spatial.github.io/sf/). Using the `sf` package allows us to more easily work with raster and polygon data in R, and to select sites from more complex spatial objects.  The `loc` parameter works with the simple vector, [WKT](https://arthur-e.github.io/Wicket/sandbox-gmaps3.html), [geoJSON](http://geojson.io/#map=2/20.0/0.0) objects and native `sf` objects in R.

As an example of searching for sites using a location, we've created a rough representation of Denmark as a polygon.  To work with this spatial object in R we also transformed the `geoJSON` element to an object for the `sf` package.  There are many other tools to work with spatial objects in R. Regardless of how you get the data into R, `neotoma2` works with almost all objects in the `sf` package.


```r
geoJSON <- '{"coordinates": [[
            [7.92, 55.02],
            [12.42, 54.42],
            [12.86, 55.98],
            [12.41, 56.44],
            [10.63, 57.96],
            [7.74, 57.48],
            [ 7.70, 57.09],
            [7.92, 55.02]
          ]],
        "type": "Polygon"}'

denmark_sf <- geojsonsf::geojson_sf(geoJSON)

# Note here we use the `all_data` flag to capture all the sites within the polygon.
# We're using `all_data` here because we know that the site information is relatively small
# for denmark. If we were working in a new area or with a new search we would limit the
# search size.
denmark_sites <- neotoma2::get_sites(loc = denmark_sf, all_data = TRUE)
```

You can always simply `plot()` the `sites` objects, but you will lose some of the geographic context.  The `plotLeaflet()` function returns a `leaflet()` map, and allows you to further customize it, or add additional spatial data (like our original bounding polygon, `sa_sf`, which works directly with the R `leaflet` package):

##### Code

Note the use of the `%>%` pipe here. If you are not familiar with this symbol, check our ["Piping in R" section](#piping-in-r) of the Appendix.


```r
neotoma2::plotLeaflet(denmark_sites) %>% 
  leaflet::addPolygons(map = ., 
                       data = denmark_sf, 
                       color = "green")
```

##### Result


```{=html}
<div class="leaflet html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-0fa5844d74cef4693237" style="width:672px;height:480px;"></div>
<script type="application/json" data-for="htmlwidget-0fa5844d74cef4693237">{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addProviderTiles","args":["Stamen.TerrainBackground",null,null,{"errorTileUrl":"","noWrap":false,"detectRetina":false}]},{"method":"addTiles","args":["https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":1,"detectRetina":false,"attribution":"&copy; <a href=\"https://openstreetmap.org\">OpenStreetMap<\/a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA<\/a>"}]},{"method":"addCircleMarkers","args":[[56.281938,56.28818,56.12833,55.61667,55.625,56.40538,56.8526,56.03796,56.29111],[12.522662,12.519322,8.613126,9.71667,9.84222,9.84009,10.1735,8.91161,12.50556],10,null,null,{"interactive":true,"draggable":false,"keyboard":true,"title":"","alt":"","zIndexOffset":0,"opacity":1,"riseOnHover":true,"riseOffset":250,"stroke":true,"color":"#03F","weight":5,"opacity.1":0.5,"fill":true,"fillColor":"#03F","fillOpacity":0.2},{"showCoverageOnHover":true,"zoomToBoundsOnClick":true,"spiderfyOnMaxZoom":true,"removeOutsideVisibleBounds":true,"spiderLegPolylineOptions":{"weight":1.5,"color":"#222","opacity":0.5},"freezeAtZoom":false},null,["<b>Björkeröds Mosse<\/b><br><b>Description:<\/b> Open fen dammed and flooded in 1970's to create a bird pond. \r\nPhysiography: Exposed hillslope of Björkeröd plateau. Surrounding vegetation: Alder fen, beech wood, pasture, arable.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3019>Explorer Link<\/a>","<b>Håkulls Mosse<\/b><br><b>Description:<\/b> Water filled remnant of peat cutting. Physiography: in a narrow valley with steep sides. Surrounding vegetation: mixed beech-oak forest with pine+spruce.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3138>Explorer Link<\/a>","<b>Lake Solsø<\/b><br><b>Description:<\/b> Strongly drained lake, now mostly fen. Physiography: almost flat landscape, 30-90 asl heights. Surrounding vegetation: dry-moist pasture, fertilized.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3432>Explorer Link<\/a>","<b>Vejlby<\/b><br><b>Description:<\/b> Infilled gravel pit.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3491>Explorer Link<\/a>","<b>Trelde Klint<\/b><br><b>Description:<\/b> Lacustrine deposits of interglacial paleolake. Physiography: Basin.<br><a href=http://apps.neotomadb.org/explorer/?siteids=14265>Explorer Link<\/a>","<b>Hollerup<\/b><br><b>Description:<\/b> Paleolake of Eemian age. Situated on the northern edge of the Gudenå valley 14 km southeast of Randers, between Langå and Ulstrup, in the eastern part of central Jylland.<br><a href=http://apps.neotomadb.org/explorer/?siteids=23293>Explorer Link<\/a>","<b>Lille Vildmose<\/b><br><b>Description:<\/b> NA<br><a href=http://apps.neotomadb.org/explorer/?siteids=26004>Explorer Link<\/a>","<b>Harreskov<\/b><br><b>Description:<\/b> Cromer interglacial locality (Harreskov type) from middle Pleistocene. Sediments are made of calcareous gyttja overlain by diatomaceous gyttja.<br><a href=http://apps.neotomadb.org/explorer/?siteids=27349>Explorer Link<\/a>","<b>Kullaberg<\/b><br><b>Description:<\/b> Bog. Physiography: depression in small plateau. Surrounding vegetation: Vaccinium, Rubus, Betula, Fagus, Quercus.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28861>Explorer Link<\/a>"],null,null,{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]},{"method":"addPolygons","args":[[[[{"lng":[7.92,12.42,12.86,12.41,10.63,7.74,7.7,7.92],"lat":[55.02,54.42,55.98,56.44,57.96,57.48,57.09,55.02]}]]],null,null,{"interactive":true,"className":"","stroke":true,"color":"green","weight":5,"opacity":0.5,"fill":true,"fillColor":"green","fillOpacity":0.2,"smoothFactor":1,"noClip":false},null,null,null,{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]}],"limits":{"lat":[54.42,57.96],"lng":[7.7,12.86]}},"evals":[],"jsHooks":[]}</script>
```

#### `site` Object Helpers {.tabset}

If we look at the [data structure diagram](#222-data-structures-in-neotoma2) for the objects in the `neotoma2` R package we can see that there are a set of functions that can operate on `sites`.  As we retrieve more information for `sites` objects, using `get_datasets()` or `get_downloads()`, we are able to use more of these helper functions.

As it is, we can take advantage of functions like `summary()` to get a more complete sense of the types of data we have in `denmark_sites`.  The following code gives the summary table. We do some R magic here to change the way the data is displayed (turning it into a [`DT::datatable()`](https://rstudio.github.io/DT/) object), but the main piece is the `summary()` call.

##### Code


```r
# Give information about the sites themselves, site names &cetera.
neotoma2::summary(denmark_sites)
# Give the unique identifiers for sites, collection units and datasets found at those sites.
neotoma2::getids(denmark_sites)
```

##### Result


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-476bb6417c56add6d8ca" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-476bb6417c56add6d8ca">{"x":{"filter":"none","vertical":false,"data":[["3019","3019","3138","3138","3432","3432","3432","3432","3491","3491","14265","14265","14265","23293","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","26004","27349","28861","28861"],["Björkeröds Mosse","Björkeröds Mosse","Håkulls Mosse","Håkulls Mosse","Lake Solsø","Lake Solsø","Lake Solsø","Lake Solsø","Vejlby","Vejlby","Trelde Klint","Trelde Klint","Trelde Klint","Hollerup","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Lille Vildmose","Harreskov","Kullaberg","Kullaberg"],["BJORKE69","BJORKE69","HAKULLA5","HAKULLA5","SOLSOE81","SOLSOE81","SOLSOE83","SOLSOE83","VEJLBYE4","VEJLBYG5","TRELDKLA","TRELDKLA","TRELDKLA","HOLLERUP","LILVIDK1","LIVI_DK10","LIVI_DK11","LIVI_DK12","LIVI_DK13","LIVI_DK14","LIVI_DK15","LIVI_DK17","LIVI_DK18","LIVI_DK2","LIVI_DK3","LIVI_DK4","LIVI_DK5","LIVI_DK6","LIVI_DK7","LIVI_DK8","LIVI_DK9","HARRESK","KULL","KULL"],[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],["pollen","geochronologic","pollen","geochronologic","pollen","geochronologic","pollen","geochronologic","pollen","pollen","geochronologic","charcoal","pollen","pollen","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","testate amoebae surface sample","pollen","geochronologic","pollen"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>siteid<\/th>\n      <th>sitename<\/th>\n      <th>collectionunit<\/th>\n      <th>chronolgies<\/th>\n      <th>datasets<\/th>\n      <th>types<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":[3,4]}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

In this document we list only the first 10 records (there are more, you can use `length(datasets(denmark_sites))` to see how many datasets you've got). We can see that there are no chronologies associated with the `site` objects. This is because, at present, we have not pulled in the `dataset` information we need. In Neotoma, a chronology is associated with a collection unit (and that metadata is pulled by `get_datasets()` or `get_downloads()`). All we know from `get_sites()` are the kinds of datasets we have and the location of the sites that contain the datasets.

### `get_datasets()` {.tabset}

Within Neotoma, collection units and datasets are contained within sites.  Similarly, a `sites` object contains `collectionunits` which contain `datasets`. From the table above (Result tab in Section 3.1.3.2) we can see that some of the sites we've looked at contain pollen records, some contain geochronologic data and some contain other dataset types. We could write something like this: `table(summary(denmark_sites)$types)` to see the different datasettypes and their counts.

With a `sites` object we can directly call `get_datasets()` to pull in more metadata about the datasets.  The `get_datasets()` method also supports any of the search terms listed above in the [Site Search](#3-site-searches) section. At any time we can use `datasets()` to get more information about any datasets that a `sites` object may contain.  Compare the output of `datasets(denmark_sites)` to the output of a similar call using the following:

#### Code


```r
# This may be slow, because there's a lot of sites!
# denmark_datasets <- neotoma2::get_datasets(denmark_sites, all_data = TRUE)

denmark_datasets <- neotoma2::get_datasets(loc = denmark_sf, datasettype = "pollen", all_data = TRUE)

datasets(denmark_datasets)
```

#### Result


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-d46a198a47beb82d4dd9" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-d46a198a47beb82d4dd9">{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4","5","6","7","8","9","10"],["3933","4082","22319","40112","49047","53982","4445","4446","4514","4515"],["European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database","European Pollen Database"],["pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen"],[null,13337,null,null,null,5459.8,13410,10956,null,null],[null,9129,null,null,null,-37.1,-41,2410,null,null],["Data contributed by Berglund Björn E.","Data contributed by Björn E. Berglund.","Data contributed by Kunes Petr.","Dataset digitized from original counting protocols from GEUS.",null,"Data contributee by Björkman, L. to the EPD in 2017 (Landclim Project).","Data contributed by Odgaard Bent V.","Data contributed by Odgaard Bent V.","Data contributed by Andersen Svend Thorkild.","Data contributed by Andersen Svend Thorkild."]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>datasetid<\/th>\n      <th>database<\/th>\n      <th>datasettype<\/th>\n      <th>age_range_old<\/th>\n      <th>age_range_young<\/th>\n      <th>notes<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":[4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

You can see that this provides information only about the specific dataset, not the site! For a more complete record we can join site information from `summary()` to dataset information using `datasets()` using the `getids()` function which links sites, and all the collection units and datasets they contain.

### `filter()` Records {.tabset}
  
If we choose to pull in information about only a single dataset type, or if there is additional filtering we want to do before we download the data, we can use the `filter()` function.  For example, if we only want sedimentary pollen records (as opposed to pollen surface samples), and want records with known chronologies, we can filter by `datasettype` and by the presence of an `age_range_young`, which would indicate that there is a chronology that defines bounds for ages within the record.

#### Code


```r
denmark_records <- denmark_datasets %>% 
  neotoma2::filter(!is.na(age_range_young))

neotoma2::summary(denmark_records)

# We've removed records, so the new object should be shorter than the original.
length(denmark_records) < length(denmark_datasets)
```

#### Result


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-1e3983553eb91959b088" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-1e3983553eb91959b088">{"x":{"filter":"none","vertical":false,"data":[["1","2","3","4"],["3138","28861","3432","3432"],["Håkulls Mosse","Kullaberg","Lake Solsø","Lake Solsø"],["HAKULLA5","KULL","SOLSOE81","SOLSOE83"],[0,0,0,0],[1,1,1,1],["pollen","pollen","pollen","pollen"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>siteid<\/th>\n      <th>sitename<\/th>\n      <th>collectionunit<\/th>\n      <th>chronolgies<\/th>\n      <th>datasets<\/th>\n      <th>types<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":[4,5]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

We can see now that the data table looks different (comparing it to the [table above](#322-result)), and there are fewer total sites. Again, there is no explicit chronology for these records, we need to pull down the complete download for these records, but we begin to get a sense of what kind of data we have.

### Pulling in `sample()` data

Because sample data adds a lot of overhead (for this pollen data, the object that includes the dataset with samples is 20 times larger than the `dataset` alone), we try to call `get_downloads()` only after we've done our preliminary filtering. After `get_datasets()` you have enough information to filter based on location, time bounds and dataset type. When we move to `get_download()` we can do more fine-tuned filtering at the analysis unit or taxon level.

The following call can take some time, but we've frozen the object as an RDS data file. You can run this command on your own, and let it run for a bit, or you can just load the object in.


```r
## This line is commented out because we've already run it for you.
## denmark_dl <- denmark_records %>% get_downloads(all_data = TRUE)
## saveRDS(denmark_dl, "data/dkDownload.RDS")
denmark_dl <- readRDS("data/dkDownload.RDS")
```

Once we've downloaded, we now have information for each site about all the associated collection units, the datasets, and, for each dataset, all the samples associated with the datasets. To extract samples all downloads we can call:


```r
allSamp <- samples(denmark_dl)
```

When we've done this, we get a `data.frame` that is 10055 rows long and 37 columns wide.  The reason the table is so wide is that we are returning data in a **long** format.  Each row contains all the information you should need to properly interpret it:


```
##  [1] "age"             "agetype"         "ageolder"        "ageyounger"     
##  [5] "chronologyid"    "chronologyname"  "units"           "value"          
##  [9] "context"         "element"         "taxonid"         "symmetry"       
## [13] "taxongroup"      "elementtype"     "variablename"    "ecologicalgroup"
## [17] "analysisunitid"  "sampleanalyst"   "sampleid"        "depth"          
## [21] "thickness"       "samplename"      "datasetid"       "database"       
## [25] "datasettype"     "age_range_old"   "age_range_young" "datasetnotes"   
## [29] "siteid"          "sitename"        "lat"             "long"           
## [33] "area"            "sitenotes"       "description"     "elev"           
## [37] "collunitid"
```

For some dataset types or analyses, some of these columns may not be needed, however, for other dataset types they may be critically important.  To allow the `neotoma2` package to be as useful as possible for the community we've included as many as we can.

#### Extracting Taxa {.tabset}

If you want to know what taxa we have in the record you can use the helper function `taxa()` on the sites object. The `taxa()` function gives us not only the unique taxa, but two additional columns -- `sites` and `samples` -- that tell us how many sites the taxa appear in, and how many samples the taxa appear in, to help us better understand how common individual taxa are.

##### Code


```r
neotomatx <- neotoma2::taxa(denmark_dl)
```

##### Results


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-8e14e79643345f99c28f" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-8e14e79643345f99c28f">{"x":{"filter":"none","vertical":false,"data":[["NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP"],["derived",null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],["spore","&gt;25 µm","colony","colony","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen"],[677,1062,202,326,25,29,45,67,74,86,90,107,120,121,125,132,157,160,182,190],[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],["Vascular plants","Charcoal","Algae","Algae","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants","Vascular plants"],["spore","&gt;25 µm","colony","colony","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen","pollen"],["Pteridophyta","Charcoal","Pediastrum","Botryococcus","Artemisia","Betula","Caryophyllaceae","Corylus","Cyperaceae","Empetrum","Epilobium","Fagus","Geranium","Geum-type","Poaceae undiff.","Hypericum","Fabaceae undiff.","Cichorioideae","Menyanthes trifoliata","Nuphar"],["VACR","CHAR","ALGA","ALGA","UPHE","TRSH","UPHE","TRSH","UPHE","TRSH","UPHE","TRSH","UPHE","UPHE","UPHE","UPHE","UPHE","UPHE","AQVP","AQVP"],[25,64,29,20,186,156,10,59,135,134,1,44,1,72,92,22,4,137,53,15],[1,1,1,1,3,2,1,1,2,2,1,1,1,2,1,1,2,3,2,1]],"container":"<table class=\"c(&quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &#10;&quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &#10;&quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &#10;&quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;, &quot;NISP&quot;) c(&quot;derived&quot;, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, &#10;NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA) c(&quot;spore&quot;, &quot;&gt;25 µm&quot;, &quot;colony&quot;, &quot;colony&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen/spore&quot;, &quot;pollen/spore&quot;, &#10;&quot;pollen/spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;) c(677, 1062, 202, 326, 25, 29, 45, 67, 74, 86, 90, 107, 120, 121, 125, 132, 157, 160, 182, 190, 192, 210, 219, 220, 221, 230, 242, 251, 252, 253, 271, 275, 283, 285, 293, 300, 302, 309, 310, 311, 316, 317, 330, 338, 349, 355, 369, 385, 389, 391, 415, 417, 418, 420, 451, 476, 491, 495, 496, 498, 517, 539, 568, 569, 585, 586, 655, 656, 666, 667, 705, 715, 725, 733, 747, 794, 795, 806, 813, 815, 820, 821, 842, 884, 909, 947, 967, 983, 996, 997, 999, 1011, 1013, 1121, 1142, 1161, 1172, 1260, 1299, 1301, &#10;1306, 1307, 1315, 1316, 1319, 1320, 1324, 1334, 1336, 1416, 1428, 1429, 1430, 1435, 1532, 1876, 1915, 2113, 2227, 2270, 2322, 2460, 2537, 2549, 2897, 2904, 2905, 2931, 2932, 2936, 2944, 3208, 3435, 3438, 3439, 3441, 3443, 3449, 3572, 3578, 3579, 3597, 3600, 3699, 3703, 3705, 3832, 3837, 4001, 4038, 4047, 4053, 4055, 4121, 4123, 4175, 4221, 4235, 4252, 4359, 4367, 4385, 4395, 4406, 4412, 4416, 4421, 4464, 4469, 4503, 4505, 4533, 4563, 4728, 4737, 4768, 4805, 4818, 4834, 4840, 4845, 4856, 4870, 4907, &#10;4923, 4977, 5064, 5092, 5145, 5812, 5823, 9504, 9505, 9773, 27573, 33543, 33823, 38081, 38770, 46468, 905, 3713, 35429, 83, 91, 115, 168, 170, 171, 175, 234, 294, 650, 720, 750, 835, 1168, 1331, 2299, 2301, 2613, 3706, 5004, 15671) c(NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, &#10;NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA) c(&quot;Vascular plants&quot;, &quot;Charcoal&quot;, &quot;Algae&quot;, &quot;Algae&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Unidentified palynomorphs&quot;, &quot;Unidentified palynomorphs&quot;, &quot;Unidentified palynomorphs&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Fungi&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Bryophytes&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &#10;&quot;Bryophytes&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Vascular plants&quot;, &quot;Unidentified palynomorphs&quot;) c(&quot;spore&quot;, &quot;&gt;25 µm&quot;, &quot;colony&quot;, &quot;colony&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &#10;&quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen&quot;, &quot;pollen/spore&quot;, &quot;pollen/spore&quot;, &#10;&quot;pollen/spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;, &quot;spore&quot;) c(&quot;Pteridophyta&quot;, &quot;Charcoal&quot;, &quot;Pediastrum&quot;, &quot;Botryococcus&quot;, &quot;Artemisia&quot;, &quot;Betula&quot;, &quot;Caryophyllaceae&quot;, &quot;Corylus&quot;, &quot;Cyperaceae&quot;, &quot;Empetrum&quot;, &quot;Epilobium&quot;, &quot;Fagus&quot;, &quot;Geranium&quot;, &quot;Geum-type&quot;, &quot;Poaceae undiff.&quot;, &quot;Hypericum&quot;, &quot;Fabaceae undiff.&quot;, &quot;Cichorioideae&quot;, &quot;Menyanthes trifoliata&quot;, &quot;Nuphar&quot;, &quot;Nymphaea&quot;, &quot;Picea&quot;, &quot;Plantago major&quot;, &quot;Plantago lanceolata&quot;, &quot;Plantago media&quot;, &quot;Persicaria amphibia&quot;, &quot;Potentilla-type&quot;, &quot;Quercus&quot;, &quot;Ranunculaceae undiff.&quot;, &quot;Ranunculus undiff.&quot;, &quot;Salix&quot;, &quot;Sambucus&quot;, &quot;Scheuchzeria palustris&quot;, &#10;&quot;Sedum&quot;, &quot;Sparganium-type&quot;, &quot;Thalictrum&quot;, &quot;Tilia&quot;, &quot;Typha latifolia&quot;, &quot;Ulmus&quot;, &quot;Apiaceae&quot;, &quot;Utricularia&quot;, &quot;Vaccinium&quot;, &quot;Alnus&quot;, &quot;Acer&quot;, &quot;Bidens&quot;, &quot;Rosaceae undiff.&quot;, &quot;Fraxinus&quot;, &quot;Pinus&quot;, &quot;Populus&quot;, &quot;Amaranthaceae&quot;, &quot;Avena/Triticum&quot;, &quot;Poaceae&quot;, &quot;Asteroideae&quot;, &quot;Brassicaceae&quot;, &quot;Hedysarum&quot;, &quot;Pedicularis&quot;, &quot;Stachys-type&quot;, &quot;Trifolium pratense&quot;, &quot;Trifolium repens-type&quot;, &quot;Urtica&quot;, &quot;Potamogeton&quot;, &quot;Lysimachia&quot;, &quot;Arctostaphylos uva-ursi&quot;, &quot;Armeria maritima&quot;, &quot;Caltha-type&quot;, &quot;Campanula-type&quot;, &quot;Lythrum salicaria&quot;, &#10;&quot;Mentha-type&quot;, &quot;Myrica gale&quot;, &quot;Myriophyllum alterniflorum&quot;, &quot;Bistorta vivipara&quot;, &quot;Prunus&quot;, &quot;Rhamnus cathartica&quot;, &quot;Rubiaceae&quot;, &quot;Saxifraga oppositifolia-type&quot;, &quot;Viburnum opulus&quot;, &quot;Viburnum opulus-type&quot;, &quot;Humulus/Cannabis&quot;, &quot;Campanula&quot;, &quot;Ranunculus-type&quot;, &quot;Achillea-type&quot;, &quot;Circaea&quot;, &quot;Ononis-type&quot;, &quot;Persicaria maculosa-type&quot;, &quot;Ericaceae undiff.&quot;, &quot;Polygonum aviculare&quot;, &quot;Secale&quot;, &quot;Juniperus&quot;, &quot;Ranunculus acris-type&quot;, &quot;Melampyrum&quot;, &quot;Cerastium-type&quot;, &quot;Betula undiff.&quot;, &quot;Caryophyllaceae undiff.&quot;, &quot;Typha angustifolia-type&quot;, &#10;&quot;Anemone&quot;, &quot;Anemone-type&quot;, &quot;Apiaceae undiff.&quot;, &quot;Helianthemum&quot;, &quot;Alnus glutinosa&quot;, &quot;Sanguisorba officinalis&quot;, &quot;Hippophaë rhamnoides&quot;, &quot;Plantago maritima&quot;, &quot;Sorbus aucuparia&quot;, &quot;Corylus avellana&quot;, &quot;Carpinus betulus&quot;, &quot;Fagus sylvatica&quot;, &quot;Fagopyrum esculentum&quot;, &quot;Viscum&quot;, &quot;Centaurea cyanus&quot;, &quot;Galium-type&quot;, &quot;Filipendula&quot;, &quot;Carpinus&quot;, &quot;Crataegus&quot;, &quot;Sorbus&quot;, &quot;Rumex acetosella-type&quot;, &quot;Vicia/Lathyrus&quot;, &quot;Senecio-type&quot;, &quot;Poaceae (&gt;40 µm)&quot;, &quot;Rhynchospora alba&quot;, &quot;Gentiana pneumonanthe&quot;, &quot;Frangula alnus&quot;, &quot;Carduus&quot;, &#10;&quot;Heracleum&quot;, &quot;Dianthus-type&quot;, &quot;Calluna vulgaris&quot;, &quot;Lotus&quot;, &quot;Plantago major/P. media&quot;, &quot;Rhinanthus-type&quot;, &quot;Spergula&quot;, &quot;Spergularia&quot;, &quot;Caltha palustris&quot;, &quot;Betula nana&quot;, &quot;Populus tremula&quot;, &quot;Anthemis-type&quot;, &quot;Aster-type&quot;, &quot;Centaurea scabiosa&quot;, &quot;Rosaceae cf. Sorbus&quot;, &quot;Genista-type&quot;, &quot;Ephedra distachya-type&quot;, &quot;Ephedra fragilis-type&quot;, &quot;Fraxinus excelsior&quot;, &quot;Sambucus nigra-type&quot;, &quot;Solanum dulcamara&quot;, &quot;Parnassia palustris&quot;, &quot;Silene-type&quot;, &quot;Hordeum-type&quot;, &quot;Apium-type&quot;, &quot;Arctium&quot;, &quot;Centaurea jacea-type&quot;, &quot;Stellaria palustris&quot;, &#10;&quot;Dryas octopetala&quot;, &quot;Rumex acetosa&quot;, &quot;Rumex crispus-type&quot;, &quot;Lobelia dortmanna&quot;, &quot;Scrophularia-type&quot;, &quot;Cornus suecica&quot;, &quot;Daucus-type&quot;, &quot;Drosera rotundifolia/D. anglica&quot;, &quot;Erica tetralix&quot;, &quot;Gypsophila&quot;, &quot;Hedera helix&quot;, &quot;Hornungia-type&quot;, &quot;Hydrocotyle vulgaris&quot;, &quot;Ilex aquifolium&quot;, &quot;Jasione montana&quot;, &quot;Juniperus communis&quot;, &quot;Succisa pratensis&quot;, &quot;Lonicera periclymenum&quot;, &quot;Lonicera xylosteum&quot;, &quot;Maianthemum-type&quot;, &quot;Malus&quot;, &quot;Mercurialis perennis&quot;, &quot;Narthecium-type&quot;, &quot;Radiola linoides&quot;, &quot;Ranunculus peltatus-type&quot;, &#10;&quot;Rubus idaeus-type&quot;, &quot;Saxifraga hirculus-type&quot;, &quot;Saxifraga aizoides-type&quot;, &quot;Schoenus-type&quot;, &quot;Schoenoplectus lacustris-type&quot;, &quot;Scleranthus annuus&quot;, &quot;Sinapis-type&quot;, &quot;Taxus baccata&quot;, &quot;Trientalis europaea&quot;, &quot;Trollius europaeus&quot;, &quot;Viscum album&quot;, &quot;Carex-type&quot;, &quot;Sanicula europaea&quot;, &quot;Anemone nemorosa&quot;, &quot;Rumex acetosa/R. acetosella&quot;, &quot;Cannabis-type&quot;, &quot;Rumex/Oxyria&quot;, &quot;Menyanthes&quot;, &quot;Calluna&quot;, &quot;Ranunculus sect. Batrachium&quot;, &quot;Poaceae undiff. (&lt;40 µm)&quot;, &quot;Poterium sanguisorba&quot;, &quot;Silene-type undiff.&quot;, &quot;Plantago uniflora&quot;, &#10;&quot;Ericaceae cf. Vaccinium&quot;, &quot;Indeterminable undiff.&quot;, &quot;Varia&quot;, &quot;Indeterminable (unknown)&quot;, &quot;Dryopteris-type&quot;, &quot;Equisetum&quot;, &quot;Fungi undiff.&quot;, &quot;Lycopodium annotinum&quot;, &quot;Lycopodium clavatum&quot;, &quot;Diphasiastrum complanatum-type&quot;, &quot;Huperzia selago&quot;, &quot;Polypodiaceae&quot;, &quot;Sphagnum&quot;, &quot;Lycopodium annotinum-type&quot;, &quot;Pteridium aquilinum&quot;, &quot;Selaginella selaginoides&quot;, &quot;Polypodium&quot;, &quot;Bryophyta&quot;, &quot;Ophioglossum vulgatum&quot;, &quot;Polypodiaceae undiff.&quot;, &quot;Polypodium vulgare&quot;, &quot;Isoëtes lacustris&quot;, &quot;Isoëtes setacea&quot;, &quot;Gymnocarpium dryopteris&quot;, &#10;&quot;Unknown (pre-Quaternary)&quot;) c(&quot;VACR&quot;, &quot;CHAR&quot;, &quot;ALGA&quot;, &quot;ALGA&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;AQVP&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &#10;&quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &#10;&quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &#10;&quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;AQVP&quot;, &quot;TRSH&quot;, &quot;AQVP&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;UPHE&quot;, &quot;TRSH&quot;, &quot;UNID&quot;, &quot;UNID&quot;, &quot;UNID&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;FUNG&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;AQBR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;UPBR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;VACR&quot;, &quot;AQVP&quot;, &quot;AQVP&quot;, &quot;VACR&quot;, &quot;ANAC&quot;) c(25, 64, 29, 20, 186, 156, 10, 59, 135, 134, 1, 44, 1, 72, 92, 22, 4, 137, 53, 15, 62, 63, 89, 98, 69, 3, 164, 153, 3, 71, 188, 7, 4, 4, 62, 90, 137, 74, 215, 71, 2, 47, 64, 24, 1, 46, 54, 227, 72, 150, 7, 71, 80, 97, 71, 4, 3, 2, 14, 136, 99, 30, 1, 70, 4, 13, 7, 6, 45, 70, 64, 77, 2, 71, 71, 71, 2, 33, 4, 17, 21, 1, 73, 9, 73, 7, 32, 30, 46, 125, 84, 71, 2, 2, 5, 70, 17, 71, 89, 64, 74, 80, 35, 159, 42, 49, 2, 1, 2, 53, 153, 19, 4, 71, 88, 43, 41, 22, 14, 14, 20, 1, 7, 72, 92, 26, 3, 9, 16, 1, &#10;5, 65, 67, 11, 3, 1, 8, 48, 71, 71, 77, 1, 1, 63, 77, 24, 12, 1, 1, 1, 68, 48, 10, 8, 3, 1, 60, 3, 2, 71, 32, 1, 34, 2, 65, 85, 26, 1, 1, 1, 1, 9, 1, 1, 11, 8, 1, 71, 19, 18, 3, 18, 2, 2, 1, 3, 92, 1, 22, 39, 1, 71, 3, 43, 57, 64, 1, 9, 73, 5, 35, 66, 64, 154, 112, 35, 2, 19, 1, 64, 63, 176, 64, 94, 60, 8, 42, 1, 63, 15, 88, 78, 18, 33) c(1, 1, 1, 1, 3, 2, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 2, 3, 2, 1, 1, 2, 2, 2, 1, 1, 3, 2, 1, 1, 3, 1, 1, 1, 1, 3, 2, 2, 3, 1, 1, 1, 1, 2, 1, 1, 1, 3, 2, 3, 1, 1, 2, 2, 1, 1, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 2, 1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 1, 1, 3, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 1, 2, 1, 1, 2, 1, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, &#10;1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 1, 2, 1, 1, 1, 3, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)\">\n  <thead>\n    <tr>\n      <th>units<\/th>\n      <th>context<\/th>\n      <th>element<\/th>\n      <th>taxonid<\/th>\n      <th>symmetry<\/th>\n      <th>taxongroup<\/th>\n      <th>elementtype<\/th>\n      <th>variablename<\/th>\n      <th>ecologicalgroup<\/th>\n      <th>samples<\/th>\n      <th>sites<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":[3,9,10]}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

#### Understanding Taxonomies in Neotoma {-}

Taxonomies in Neotoma are not as straightforward as we might expect. Taxonomic identification in paleoecology can be complex, impacted by the morphology of the object we are trying to identify, the condition of the palynomorph, the expertise of the analyst, and many other conditions. You can read more about concepts of taxonomy within Neotoma in the Neotoma Manual's [section on Taxonomic concepts](https://open.neotomadb.org/manual/database-design-concepts.html#taxonomy-and-synonymy).

We use the unique identifiers (*e.g.*, `taxonid`, `siteid`, `analysisunitid`) throughout the package, since they help us to link between records. The `taxonid` values returned by the `taxa()` call can be linked to the `taxonid` column in the `samples()` table.  This allows us to build taxon harmonization tables if we choose to. You may also note that the `taxonname` is in the field `variablename`.  Individual sample counts are reported in Neotoma as [`variables`](https://open.neotomadb.org/manual/taxonomy-related-tables-1.html#Variables). A "variable" may be either a species, something like laboratory measurements, or a non-organic proxy, like charcoal or XRF measurements, and includes the units of measurement and the value.

#### Simple Harmonization {.tabset}

Let's say we want all samples from which *Poaceae* (grass) taxa have been reported to be grouped together into one pseudo-taxon called *Poaceae-undiff*. **NOTE**, this is may not be an ecologically useful grouping, but is used here for illustration.

There are several ways of grouping taxa, either directly by exporting the file and editing each individual cell, or by creating an external "harmonization" table (which we did in the prior `neotoma` package).  First, lets look for how many different ways *Poaceae* appears in these records. We can use the function `str_detect()` from the `stringr` package to look for patterns, and then return either `TRUE` or `FALSE` when the string is detected:


```
## # A tibble: 4 × 11
## # Groups:   units, context, element, taxonid, symmetry, taxongroup,
## #   elementtype, variablename, ecologicalgroup [4]
##   units context element taxonid symmetry taxongroup     elementtype variablename
##   <chr> <chr>   <chr>     <int> <lgl>    <chr>          <chr>       <chr>       
## 1 NISP  <NA>    pollen      125 NA       Vascular plan… pollen      Poaceae und…
## 2 NISP  <NA>    pollen      417 NA       Vascular plan… pollen      Poaceae     
## 3 NISP  <NA>    pollen     2113 NA       Vascular plan… pollen      Poaceae (>4…
## 4 NISP  <NA>    pollen    33543 NA       Vascular plan… pollen      Poaceae und…
## # ℹ 3 more variables: ecologicalgroup <chr>, samples <int>, sites <int>
```

We can harmonize taxon by taxon a number of different ways. One way would be to get every instance of a *Poaceae* taxon and just change them directly. Here we are taking the column `variablename` from the `allSamp` object (this is where the count data is). The square brackets are telling us which rows we're changing, here only rows where we detect `"Poaceae"` in the variable name. For each of those rows, in that column, we assign the value `"Poaceae undiff"`:



There were originally 4 different taxa identified as being within the genus *Poaceae* (including *Poaceae*., *Poaceae (>40 µm)*, and *Poaceae undiff. (<40 µm)*). The above code reduces them all to a single taxonomic group *Poaceae undiff*.

Note that this changes *Poaceae* in the `allSamp` object _only_, not in any of the downloaded objects. If we were to call `samples()` again, the taxonomy would return to its original form.

A second way to harmonize taxa is to use an external table, which is especially useful if we want to have an artifact of our choices. For example, a table of pairs (what we want changed, and the name we want it replaced with) can be generated, and it can include regular expressions (if we choose):

| original | replacement |
| -------- | ----------- |
| Poaceae.*  | Poaceae-undiff |
| Picea.* | Picea-undiff |
| Plantago.* | Plantago-undiff |
| Quercus.*  | Quercus-undiff |
| ... | ... |

We can get the list of original names directly from the `taxa()` call, applied to a `sites` object that contains samples, and then export it using `write.csv()`.


```r
taxaplots <- taxa(denmark_dl)
# Save the taxon list to file so we can edit it subsequently.
readr::write_csv(taxaplots, "data/mytaxontable.csv")
```

#### Looking at the Taxonomic Structure {.tabset}

The `taxa` function returns all our taxonomic information, and it provides some additional information, the columns `samples` and `sites` which record the number of samples across all datasets that contain the taxon, and the number of sites with the taxon. The plot below shows the relationship between samples and sites, which we would expect to be somewhat skewed, as it is.

This is effectively a rarefaction curve, the more sites a taxon is found at, the more samples it is found at.

##### Code


```r
taxaplots <- taxa(denmark_dl)
ggplot(data = taxaplots, aes(x = sites, y = samples)) +
  geom_point() +
  stat_smooth(method = 'glm', 
              method.args = list(family = 'poisson')) +
  xlab("Number of Sites") +
  ylab("Number of Samples") +
  theme_bw()
```

##### Result

![**Figure**. *A plot of the number of sites a taxon appears in, against the number of samples a taxon appears in.*](simple_workflow_files/figure-html/PlotTaxonCounts-1.png)
  
#### Editing the Taxonomy Table {-}

The plot (above) is mostly for illustration, but we can see, as a sanity check, that the relationship is as we'd expect. Here, each point represents a separate taxon, roughly, so there is a large density of points (taxa) that plot in the lower left section of the figure, and fewer points in the upper right. This means that there are a large number of taxa that are rarely present and then several that are quite common.

Exporting the taxon table to a `csv` file allows us to edit the table, filtering and selecting taxa based on contextual information, such as the `ecologicalgroup` or `taxongroup` to help you out. Once you've cleaned up the translation table you can load it in (try to save it under a different file name!), and then apply the transformation:


```r
translation <- readr::read_csv("data/taxontable.csv")
```

I did a bunch of work here. . . Then we read it in.


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-838fd37ce364af68cab8" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-838fd37ce364af68cab8">{"x":{"filter":"none","vertical":false,"data":[[338,820,330,1299,391,1142,5145,1161,3438,311,1172,3832,3837,568,569,25,418,3439,415,29,3208,1011,349,705,326,420,1168,9773,2897,2944,585,813,586,5823,2460,5064,1429,1319,45,1013,1336,4001,3441,999,1062,160,821,4175,67,1316,1430,74,4221,2549,171,4235,4047,83,86,3572,3578,90,91,4252,46468,909,157,1324,107,1320,1428,2322,369,3579,115,1416,3449,2270,120,121,5004,4359,4367,451,1260,2537,1306,3705,4385,806,175,4395,132,4406,35429,905,2613,3706,4412,983,4416,4121,4464,4469,2904,168,650,170,539,655,4503,4505,997,656,9505,182,4533,666,667,4563,190,192,842,1331,3699,202,476,230,884,210,385,220,219,2905,1307,221,38770,417,2113,125,33543,947,234,2299,835,2301,389,3435,517,242,33823,715,720,677,251,4728,252,996,4737,27573,253,815,725,2931,2227,3443,355,733,4768,4053,5812,1532,4055,9504,271,275,3597,1301,5092,4818,4805,747,283,4840,4834,4845,4123,967,285,750,1915,3703,38081,4856,3600,1435,1315,293,2932,2936,294,491,4038,4421,4870,300,302,4907,495,496,4923,1121,309,310,15671,498,316,317,3713,794,795,1876,1334,4977],["Acer","Achillea-type","Alnus","Alnus glutinosa","Amaranthaceae","Anemone","Anemone nemorosa","Anemone-type","Anthemis-type","Apiaceae","Apiaceae undiff.","Apium-type","Arctium","Arctostaphylos uva-ursi","Armeria maritima","Artemisia","Asteroideae","Aster-type","Avena/Triticum","Betula","Betula nana","Betula undiff.","Bidens","Bistorta vivipara","Botryococcus","Brassicaceae","Bryophyta","Calluna","Calluna vulgaris","Caltha palustris","Caltha-type","Campanula","Campanula-type","Cannabis-type","Carduus","Carex-type","Carpinus","Carpinus betulus","Caryophyllaceae","Caryophyllaceae undiff.","Centaurea cyanus","Centaurea jacea-type","Centaurea scabiosa","Cerastium-type","Charcoal","Cichorioideae","Circaea","Cornus suecica","Corylus","Corylus avellana","Crataegus","Cyperaceae","Daucus-type","Dianthus-type","Diphasiastrum complanatum-type","Drosera rotundifolia/D. anglica","Dryas octopetala","Dryopteris-type","Empetrum","Ephedra distachya-type","Ephedra fragilis-type","Epilobium","Equisetum","Erica tetralix","Ericaceae cf. Vaccinium","Ericaceae undiff.","Fabaceae undiff.","Fagopyrum esculentum","Fagus","Fagus sylvatica","Filipendula","Frangula alnus","Fraxinus","Fraxinus excelsior","Fungi undiff.","Galium-type","Genista-type","Gentiana pneumonanthe","Geranium","Geum-type","Gymnocarpium dryopteris","Gypsophila","Hedera helix","Hedysarum","Helianthemum","Heracleum","Hippophaë rhamnoides","Hordeum-type","Hornungia-type","Humulus/Cannabis","Huperzia selago","Hydrocotyle vulgaris","Hypericum","Ilex aquifolium","Indeterminable (unknown)","Indeterminable undiff.","Isoëtes lacustris","Isoëtes setacea","Jasione montana","Juniperus","Juniperus communis","Lobelia dortmanna","Lonicera periclymenum","Lonicera xylosteum","Lotus","Lycopodium annotinum","Lycopodium annotinum-type","Lycopodium clavatum","Lysimachia","Lythrum salicaria","Maianthemum-type","Malus","Melampyrum","Mentha-type","Menyanthes","Menyanthes trifoliata","Mercurialis perennis","Myrica gale","Myriophyllum alterniflorum","Narthecium-type","Nuphar","Nymphaea","Ononis-type","Ophioglossum vulgatum","Parnassia palustris","Pediastrum","Pedicularis","Persicaria amphibia","Persicaria maculosa-type","Picea","Pinus","Plantago lanceolata","Plantago major","Plantago major/P. media","Plantago maritima","Plantago media","Plantago uniflora","Poaceae","Poaceae (&gt;40 µm)","Poaceae undiff.","Poaceae undiff. (&lt;40 µm)","Polygonum aviculare","Polypodiaceae","Polypodiaceae undiff.","Polypodium","Polypodium vulgare","Populus","Populus tremula","Potamogeton","Potentilla-type","Poterium sanguisorba","Prunus","Pteridium aquilinum","Pteridophyta","Quercus","Radiola linoides","Ranunculaceae undiff.","Ranunculus acris-type","Ranunculus peltatus-type","Ranunculus sect. Batrachium","Ranunculus undiff.","Ranunculus-type","Rhamnus cathartica","Rhinanthus-type","Rhynchospora alba","Rosaceae cf. Sorbus","Rosaceae undiff.","Rubiaceae","Rubus idaeus-type","Rumex acetosa","Rumex acetosa/R. acetosella","Rumex acetosella-type","Rumex crispus-type","Rumex/Oxyria","Salix","Sambucus","Sambucus nigra-type","Sanguisorba officinalis","Sanicula europaea","Saxifraga aizoides-type","Saxifraga hirculus-type","Saxifraga oppositifolia-type","Scheuchzeria palustris","Schoenoplectus lacustris-type","Schoenus-type","Scleranthus annuus","Scrophularia-type","Secale","Sedum","Selaginella selaginoides","Senecio-type","Silene-type","Silene-type undiff.","Sinapis-type","Solanum dulcamara","Sorbus","Sorbus aucuparia","Sparganium-type","Spergula","Spergularia","Sphagnum","Stachys-type","Stellaria palustris","Succisa pratensis","Taxus baccata","Thalictrum","Tilia","Trientalis europaea","Trifolium pratense","Trifolium repens-type","Trollius europaeus","Typha angustifolia-type","Typha latifolia","Ulmus","Unknown (pre-Quaternary)","Urtica","Utricularia","Vaccinium","Varia","Viburnum opulus","Viburnum opulus-type","Vicia/Lathyrus","Viscum","Viscum album"],["Acer","Achillea","Alnus","Alnus","Amaranthaceae","Anemone","Anemone","Anemone","Anthemis","Apiaceae","Apiaceae","Apium","Arctium","Arctostaphylos","Armeria","Artemisia","Asteroideae","Aster","Avena/Triticum","Betula","Betula","Betula","Bidens","Bistorta","Botryococcus","Brassicaceae","Bryophyta","Calluna","Calluna","Caltha","Caltha","Campanula","Campanula","Cannabis","Carduus","Carex","Carpinus","Carpinus","Caryophyllaceae","Caryophyllaceae","Centaurea","Centaurea","Centaurea","Cerastium","Charcoal","Cichorioideae","Circaea","Cornus","Corylus","Corylus","Crataegus","Cyperaceae","Daucus","Dianthus","Diphasiastrum","Drosera","Dryas","Dryopteris","Empetrum","Ephedra","Ephedra","Epilobium","Equisetum","Erica","Ericaceae","Ericaceae","Fabaceae","Fagopyrum","Fagus","Fagus","Filipendula","Frangula","Fraxinus","Fraxinus","Fungi","Galium","Genista","Gentiana","Geranium","Geum","Gymnocarpium","Gypsophila","Hedera","Hedysarum","Helianthemum","Heracleum","Hippophaë","Hordeum","Hornungia","Humulus/Cannabis","Huperzia","Hydrocotyle","Hypericum","Ilex","Indeterminable","Indeterminable","Isoëtes","Isoëtes","Jasione","Juniperus","Juniperus","Lobelia","Lonicera","Lonicera","Lotus","Lycopodium","Lycopodium","Lycopodium","Lysimachia","Lythrum","Maianthemum","Malus","Melampyrum","Mentha","Menyanthes","Menyanthes","Mercurialis","Myrica","Myriophyllum","Narthecium","Nuphar","Nymphaea","Ononis","Ophioglossum","Parnassia","Pediastrum","Pedicularis","Persicaria","Persicaria","Picea","Pinus","Plantago","Plantago","Plantago","Plantago","Plantago","Plantago","Poaceae","Poaceae","Poaceae","Poaceae","Polygonum","Polypodiaceae","Polypodiaceae","Polypodium","Polypodium","Populus","Populus","Potamogeton","Potentilla","Poterium","Prunus","Pteridium","Pteridophyta","Quercus","Radiola","Ranunculaceae","Ranunculus","Ranunculus","Ranunculus","Ranunculus","Ranunculus","Rhamnus","Rhinanthus","Rhynchospora","Rosaceae","Rosaceae","Rubiaceae","Rubus","Rumex","Rumex","Rumex","Rumex","Rumex/Oxyria","Salix","Sambucus","Sambucus","Sanguisorba","Sanicula","Saxifraga","Saxifraga","Saxifraga","Scheuchzeria","Schoenoplectus","Schoenus","Scleranthus","Scrophularia","Secale","Sedum","Selaginella","Senecio","Silene","Silene","Sinapis","Solanum","Sorbusµm)","Sorbus","Sparganium","Spergula","Spergularia","Sphagnum","Stachys","Stellaria","Succisa","Taxus","Thalictrum","Tilia","Trientalis","Trifolium","Trifolium","Trollius","Typha","Typha","Ulmus","Unknown","Urtica","Utricularia","Vaccinium","Varia","Viburnum","Viburnum","Vicia/Lathyrus","Viscum","Viscum"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>taxonid<\/th>\n      <th>variablename<\/th>\n      <th>harmonizedname<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":0}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

You can see we've changed some of the taxon names in the taxon table.  To replace the names in the `samples()` output, we'll join the two tables using an `inner_join()` (meaning the `variablename` must appear in both tables for the result to be included), and then we're going to select only those elements of the sample tables that are relevant to our later analysis, using the `harmonizedname` column as our new name for the taxa:


```r
allSamp <- samples(denmark_dl)

allSamp <- allSamp %>%
  inner_join(translation, by = c("variablename" = "variablename")) %>% 
  dplyr::select(!c("variablename")) %>% 
  group_by(siteid, sitename, harmonizedname,
           sampleid, units, age,
           agetype, depth, datasetid,
           long, lat) %>%
  summarise(value = sum(value), .groups='keep')
```


```{=html}
<div class="datatables html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-78e967a94d5f0e245395" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-78e967a94d5f0e245395">{"x":{"filter":"none","vertical":false,"data":[["3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138","3138"],["Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse","Håkulls Mosse"],["Amaranthaceae","Anemone","Apiaceae","Armeria","Artemisia","Asteroideae","Betula","Bistorta","Brassicaceae","Cerastium","Cichorioideae","Corylus","Cyperaceae","Dianthus","Dryas","Dryopteris","Empetrum","Ephedra","Equisetum","Ericaceae","Filipendula","Geum","Gypsophila","Hedysarum","Helianthemum","Hippophaë","Huperzia","Juniperus","Lycopodium","Melampyrum","Ononis","Parnassia","Pinus","Plantago","Poaceae","Populus","Potentilla","Prunus","Ranunculus","Rubiaceae","Rumex/Oxyria","Salix","Sanguisorba","Saxifraga","Selaginella","Silene","Sorbusµm)","Thalictrum","Ulmus","Urtica"],[403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172,403172],["NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP","NISP"],[9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129,9129],["Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP","Radiocarbon years BP"],[655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655,655],["4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082","4082"],[12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322,12.519322],[56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818,56.28818],[1,62,20,3,52,40,7,8,18,1,17,6,16,12,5,14,7,15,70,2,64,6,15,2,55,82,187,8,71,1,37,1,1292,41,1,2,55,686,58,1,53,6,9,48,72,54,3,3,17,6]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>siteid<\/th>\n      <th>sitename<\/th>\n      <th>harmonizedname<\/th>\n      <th>sampleid<\/th>\n      <th>units<\/th>\n      <th>age<\/th>\n      <th>agetype<\/th>\n      <th>depth<\/th>\n      <th>datasetid<\/th>\n      <th>long<\/th>\n      <th>lat<\/th>\n      <th>value<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"className":"dt-right","targets":[3,5,7,9,10,11]}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

We now have a cleaner set of taxon names compared to the original table, both because of harmonization, and because we cleared out many of the non-**TRSH** (trees and shrubs) taxa from the harmonization table. Plotting the same set of taxa with the new harmonized names results in this plot:

![**Figure**. *The same site/sample plot as above, with with the new harmonized taxonomy. Note that the distribution of points along the curve is smoother, as we remove some of the taxonomic issues.*](simple_workflow_files/figure-html/origTableOut-1.png)

## Simple Analytics

### Stratigraphic Plotting {.tabset}

To plot at strategraphic diargram we are only interested in one site and in one dataset. By looking at the summary of downloads we can see that Lake Solsø has two collection units that both have a pollen record. Lets look at the SOLSOE81 collection unit, which is the second download. To get the samples from just that one collection unit by specifying that you want only the samples from the second download. 

We can use packages like `rioja` to do stratigraphic plotting for a single record, but first we need to do some different data management.  Although we could do harmonization again we're going to simply take the taxa at a single site and plot them in a stratigraphic diagram. However, if you would like to plot multiple sites and you want them to have harmonized taxa we have provided examples on how to do both. 

#### Raw Taxon

```r
# Get a particular site, in this case we are simply subsetting the
# `denmark_dl` object to get Lake Solsø:
plottingSite <- denmark_dl[[2]]

# Select only pollen measured using NISP and convert to a "wide"
# table, using proportions. The first column will be "age".
# This turns our "long" table into a "wide" table:
counts <- plottingSite %>%
  samples() %>%
  toWide(ecologicalgroup = c("TRSH"),
         unit = c("NISP"),
         elementtypes = c("pollen"),
         groupby = "age",
         operation = "prop") %>%
  arrange(age)

counts <- counts[, colSums(counts > 0.01, na.rm = TRUE) > 5]
```

#### With Harmonization

```r
# Get a particular site, in this case we are simply subsetting the
# `denmark_dl` object to get Lake Solsø:
plottingSite <- denmark_dl[[2]]

# Select only pollen measured using NISP and convert to a "wide"
# table, using proportions. The first column will be "age".
# This turns our "long" table into a "wide" table:
counts_harmonized <- plottingSite %>%
  samples() %>%
  toWide(ecologicalgroup = c("TRSH"),
         unit = c("NISP"),
         elementtypes = c("pollen"),
         groupby = "age",
         operation = "prop") %>%
  arrange(age) %>%
  pivot_longer(-age) %>%
  inner_join(translation, by = c("name" = "variablename")) %>% 
  dplyr::select(!c("name", taxonid)) %>% 
  group_by(harmonizedname, age) %>%
  summarise(value = sum(value), .groups='keep')%>%
  pivot_wider(names_from = harmonizedname, values_from = value)

counts_harmonized <- counts_harmonized[, colSums(counts_harmonized > 0.01, na.rm = TRUE) > 5]
```

### {.tabset}

Hopefully the code is pretty straightforward. The `toWide()` function provides you with significant control over the taxa, units and other elements of your data before you get them into the wide matrix (`depth` by `taxon`) that most statistical tools such as the `vegan` package or `rioja` use.

To plot the data we can use `rioja`'s `strat.plot()`, sorting the taxa using weighted averaging scores (`wa.order`). I've also added a CONISS plot to the edge of the the plot, to show how the new *wide* data frame works with distance metric funcitons.

#### Raw Taxon


```r
# Perform constrained clustering:
clust <- rioja::chclust(dist(sqrt(counts)),
                        method = "coniss")

# Plot the stratigraphic plot, converting proportions to percentages:
plot <- rioja::strat.plot(counts[,-1] * 100, yvar = counts$age,
                  title = denmark_dl[[1]]$sitename,
                  ylabel = "Calibrated Years BP",
                  xlabel = "Pollen (% of Trees and Shrubs)",
                  srt.xlabel = 70,
                  y.rev = TRUE,
                  clust = clust,
                  wa.order = "topleft",
                  scale.percent = TRUE)

rioja::addClustZone(plot, clust, 4, col = "red")
```

<img src="simple_workflow_files/figure-html/plotStrigraphraw-1.png" width="90%" />

#### With Harmonization

```r
# Perform constrained clustering:
clust <- rioja::chclust(dist(sqrt(counts_harmonized)),
                        method = "coniss")

# Plot the stratigraphic plot, converting proportions to percentages:
plot <- rioja::strat.plot(counts_harmonized[,-1] * 100, yvar = counts_harmonized$age,
                  title = denmark_dl[[1]]$sitename,
                  ylabel = "Calibrated Years BP",
                  xlabel = "Pollen (% of Trees and Shrubs)",
                  srt.xlabel = 70,
                  y.rev = TRUE,
                  clust = clust,
                  wa.order = "topleft",
                  scale.percent = TRUE)

rioja::addClustZone(plot, clust, 4, col = "red")
```

<img src="simple_workflow_files/figure-html/plotStrigraphharm-1.png" width="90%" />

###

## Conclusion

So, we've done a lot in this example.  We've (1) searched for sites using site names and geographic parameters, (2) filtered results using temporal and spatial parameters, (3) obtained sample information for the selected datasets and (4) performed basic analysis including the use of climate data from rasters.  Hopefully you can use these examples as templates for your own future work, or as a building block for something new and cool!

## Appendix Sections

### Installing packages on your own {#localinstall}

We use several packages in this document, including `leaflet`, `sf` and others. We load the packages using the `pacman` package, which will automatically install the packages if they do not currently exist in your set of packages.


```r
options(warn = -1)
pacman::p_load(neotoma2, dplyr, ggplot2, sf, geojsonsf, leaflet, terra, DT, readr, stringr, rioja)
```

Note that R is sensitive to the order in which packages are loaded.  Using `neotoma2::` tells R explicitly that you want to use the `neotoma2` package to run a particular function. So, for a function like `filter()`, which exists in other packages such as `dplyr`, you may see an error that looks like:

```bash
Error in UseMethod("filter") : 
  no applicable method for 'filter' applied to an object of class "sites"
```

In that case it's likely that the wrong package is trying to run `filter()`, and so explicitly adding `dplyr::` or `neotoma2::` in front of the function name (i.e., `neotoma2::filter()`)is good practice.

### Piping in `R` {.tabset}

Piping is a technique that simplifies the process of chaining multiple operations on a data object. It involves using either of these operators: `|>` or `%>%`. `|>` is a base R operator while `%>%` comes from the `tidyverse` ecosystem in R. In `neotoma2` we use `%>%`.

The pipe operator works as a real-life pipe, which carries water from one location to another. In programming, the output of the function on the left-hand side of the pipe is taken as the initial argument for the function on the right-hand side of the pipe. It helps by making code easier to write and read. Additionally, it reduces the number of intermediate objects created during data processing, which can make code more memory-efficient and faster.

Without using pipes you can use the `neotoma2` R package to retrieve a site and then plot it by doing:

```r
# Retrieve the site
plot_site <- neotoma2::get_sites(sitename = "%ø%")
# Plot the site
neotoma2::plotLeaflet(object = plot_site)
```

This would create a variable `plot_site` that we will not need any more, but it was necessary so that we could pass it to the `plotLeaflet` function.

With the pipe (`%>%`) we do not need to create the variable, we can just rewrite our code.  Notice that `plotLeaflet()` doesn't need the `object` argument because the response of `get_sites(sitename = "%ø%")` gets passed directly into the function.

#### 2.2.3.1. Code


```r
# get_sites and pipe. The `object` parameter for plotLeaflet will be the
# result of the `get_sites()` function.
get_sites(sitename = "%ø%") %>%
  plotLeaflet()
```

#### 2.2.3.2. Result


```{=html}
<div class="leaflet html-widget html-fill-item-overflow-hidden html-fill-item" id="htmlwidget-bf5a3f4dd6df59bde83c" style="width:672px;height:480px;"></div>
<script type="application/json" data-for="htmlwidget-bf5a3f4dd6df59bde83c">{"x":{"options":{"crs":{"crsClass":"L.CRS.EPSG3857","code":null,"proj4def":null,"projectedBounds":null,"options":{}}},"calls":[{"method":"addProviderTiles","args":["Stamen.TerrainBackground",null,null,{"errorTileUrl":"","noWrap":false,"detectRetina":false}]},{"method":"addTiles","args":["https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",null,null,{"minZoom":0,"maxZoom":18,"tileSize":256,"subdomains":"abc","errorTileUrl":"","tms":false,"noWrap":false,"zoomOffset":0,"zoomReverse":false,"opacity":1,"zIndex":1,"detectRetina":false,"attribution":"&copy; <a href=\"https://openstreetmap.org\">OpenStreetMap<\/a> contributors, <a href=\"https://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA<\/a>"}]},{"method":"addCircleMarkers","args":[[64.910744,56.12833,82.333,62.331198,60.71667,61.41667,59.81667,61.5625,68.44417,59.625946,59.34349,59.669884,58.537336,59.76475,79.74,62.46667,62.38333,62.32361,62.4,79.74,78.1,78.2,78.2,78.2,78.2],[11.6594,8.613126,-23.846,10.397466,7,8.66667,6,10.26778,18.07167,7.986352,7.30483,7.540184,7.73367,7.433998,10.80421,9.61667,9.66667,9.73833,9.68333,10.80421,14.1,15.75,15.75,15.75,15.75],10,null,null,{"interactive":true,"draggable":false,"keyboard":true,"title":"","alt":"","zIndexOffset":0,"opacity":1,"riseOnHover":true,"riseOffset":250,"stroke":true,"color":"#03F","weight":5,"opacity.1":0.5,"fill":true,"fillColor":"#03F","fillOpacity":0.2},{"showCoverageOnHover":true,"zoomToBoundsOnClick":true,"spiderfyOnMaxZoom":true,"removeOutsideVisibleBounds":true,"spiderLegPolylineOptions":{"weight":1.5,"color":"#222","opacity":0.5},"freezeAtZoom":false},null,["<b>Blåvasstjønn<\/b><br><b>Description:<\/b> Lake with surrounding fen. Physiography: underlying bedrock (Amphibole/Gneiss). Surrounding vegetation: mixed pine/spruce forest/ombrogenic mire.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3022>Explorer Link<\/a>","<b>Lake Solsø<\/b><br><b>Description:<\/b> Strongly drained lake, now mostly fen. Physiography: almost flat landscape, 30-90 asl heights. Surrounding vegetation: dry-moist pasture, fertilized.<br><a href=http://apps.neotomadb.org/explorer/?siteids=3432>Explorer Link<\/a>","<b>Kap København<\/b><br><b>Description:<\/b> The Kap København Formation consists of shallow marine deposits containing terrestrially-derived organic materials. Outcrops occur about 230 m above Mudderbugt as a result of glacioisostatic and eustatic sea-level changes. <br><a href=http://apps.neotomadb.org/explorer/?siteids=10066>Explorer Link<\/a>","<b>Lake Flåfattjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Plateau. Surrounding vegetation: Birch forest. Vegetation formation: Alpine zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13383>Explorer Link<\/a>","<b>Trettetjørn<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Plateau. Surrounding vegetation: Betula pubescens and scattered birch. Vegetation formation: Low-alpine vegetation zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13390>Explorer Link<\/a>","<b>Brurskardtjørni<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Montain. Surrounding vegetation: Salix and Betula shrubs, open grassland. Vegetation formation: Low alpine vegetation.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13391>Explorer Link<\/a>","<b>Vestre Øykjamyrtjørn<\/b><br><b>Description:<\/b> Bedrock basin. Physiography: Fjord. Surrounding vegetation: Just above tree-line Betula alnus. Vegetation formation: Boreonemoral zone.<br><a href=http://apps.neotomadb.org/explorer/?siteids=13392>Explorer Link<\/a>","<b>Måsåtjørnet<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Mid-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26129>Explorer Link<\/a>","<b>Bjørnfjelltjørn<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: Above Betula pub. forest limit. Vegetation formation: Low Alpine.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26169>Explorer Link<\/a>","<b>Øygardstjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Middle-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26212>Explorer Link<\/a>","<b>Lisletjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Middle-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26213>Explorer Link<\/a>","<b>Flotatjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Shrubs. Vegetation formation: Northern-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26214>Explorer Link<\/a>","<b>Grostjørna<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Forest. Vegetation formation: Southern-boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26217>Explorer Link<\/a>","<b>Isbenttjønn<\/b><br><b>Description:<\/b> Lake. Physiography: Hilly area. Surrounding vegetation: Shrubs and herbs. Vegetation formation: North-Boreal.<br><a href=http://apps.neotomadb.org/explorer/?siteids=26221>Explorer Link<\/a>","<b>Søre Salatberget<\/b><br><b>Description:<\/b> steep, rocky bird cliff<br><a href=http://apps.neotomadb.org/explorer/?siteids=28135>Explorer Link<\/a>","<b>Lake Ristjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28411>Explorer Link<\/a>","<b>Lake Topptjønna<\/b><br><b>Description:<\/b> Lake. Physiography: Valley. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28412>Explorer Link<\/a>","<b>Lake Heimtjønna<\/b><br><b>Description:<\/b> Lake. Physiography: depression. Surrounding vegetation: dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28431>Explorer Link<\/a>","<b>Lake Store Finnsjøen<\/b><br><b>Description:<\/b> Lake. Physiography: depression in Mt Finnshø. Surrounding vegetation: lichen dominated dwarf-shrub tundra.<br><a href=http://apps.neotomadb.org/explorer/?siteids=28440>Explorer Link<\/a>","<b>Søre Salatberget<\/b><br><b>Description:<\/b> NA<br><a href=http://apps.neotomadb.org/explorer/?siteids=28575>Explorer Link<\/a>","<b>Bjørndalen<\/b><br><b>Description:<\/b> Erosion material near stream<br><a href=http://apps.neotomadb.org/explorer/?siteids=28578>Explorer Link<\/a>","<b>Lindholmhøgda 1<\/b><br><b>Description:<\/b> Rather dry closed moss tundra<br><a href=http://apps.neotomadb.org/explorer/?siteids=28648>Explorer Link<\/a>","<b>Lindholmhøgda 2<\/b><br><b>Description:<\/b> Rather moist closed moss tundra<br><a href=http://apps.neotomadb.org/explorer/?siteids=28652>Explorer Link<\/a>","<b>Lindholmhøgda 3<\/b><br><b>Description:<\/b> Wet peaty gully<br><a href=http://apps.neotomadb.org/explorer/?siteids=28653>Explorer Link<\/a>","<b>Lindholmhøgda 4<\/b><br><b>Description:<\/b> Very wet shallow peaty gullet<br><a href=http://apps.neotomadb.org/explorer/?siteids=28654>Explorer Link<\/a>"],null,null,{"interactive":false,"permanent":false,"direction":"auto","opacity":1,"offset":[0,0],"textsize":"10px","textOnly":false,"className":"","sticky":true},null]}],"limits":{"lat":[56.12833,82.333],"lng":[-23.846,18.07167]}},"evals":[],"jsHooks":[]}</script>
```
