---
title: "A Not so Simple Workflow"
author: "Simon Goring, Socorro Dominguez Vidaña"
date: "2026-11-05"
output:
  html_document:
    code_folding: show
    fig_caption: yes
    keep_md: yes
    self_contained: yes
    theme: readable
    toc: yes
    toc_float: yes
  pdf_document:
    pandoc_args: "-V geometry:vmargin=1in -V geometry:hmargin=1in"
dev: svg
highlight: tango
---

## Building New Chronologies

This RMarkdown document will walk you through the process of:

1. Downloading a single diatom record
2. Examining the chronologies for that record and associated chronological controls
3. Creating a new chronology for the record
4. Adding the chronology to the record
5. Switching between default chronologies

We will use the diatom core from **Heart Lake** (Adirondack Mountains, New York). The Barnegat Bay cores we used in the [simple workflow](https://open.neotomadb.org/Current_Workshop/simple_workflow.html) are dated with lead-210, which only reaches back about 150 years. Heart Lake is dated with **radiocarbon**, which is the usual way to date a core that spans thousands of years, and it is what `Bchron` was designed for. This approach is focused on a single record, but much of what is done here can be extended to multiple records using functions.

## Load Libraries

For this workshop element we need `neotoma2`, `dplyr`, `ggplot2` and `Bchron` to do the work, plus `DT` for displaying tables. We'll be loading a record from Neotoma, building a new chronology for the record, and then adding the chronology back to the record.

We'll be using the R package `pacman` here, to automatically load and install packages:


``` r
pacman::p_load(neotoma2, dplyr, ggplot2, Bchron, DT)
```

## Loading the Record

We worked through the process for finding and downloading records using `neotoma2` in the [simple workflow](https://open.neotomadb.org/Current_Workshop/simple_workflow.html). Heart Lake is [site 728](https://data.neotomadb.org/728) in Neotoma, so we can go straight to it by its site ID.

We follow the same steps as before: `get_sites()`, then `get_datasets()`, then `get_downloads()`. In between we keep only the `diatom` dataset. This site also holds pollen, water chemistry and other datasets, and we only want the diatoms.


``` r
heart_lake <- get_sites(728) %>%
  get_datasets() %>%
  neotoma2::filter(datasettype == "diatom") %>%
  get_downloads()
```

Now we use the `chronologies()` helper function to look at the chronologies associated with the record:


``` r
heart_chron <- chronologies(heart_lake)

heart_chron %>%
  as.data.frame() %>%
  dplyr::select(chronologyid, chronologyname, agemodel, modelagetype, isdefault) %>%
  DT::datatable(
    rownames = FALSE,
    options = list(scrollX = "100%", dom = "t")
  )
```

```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-4be62eb39d1a49d21773" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-4be62eb39d1a49d21773">{"x":{"filter":"none","vertical":false,"data":[["1405","34673"],["COHMAP chron 3","Neotoma 2021"],["weighted cubic regression","Bacon"],["Radiocarbon years BP","Calibrated radiocarbon years BP"],[true,true]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>chronologyid<\/th>\n      <th>chronologyname<\/th>\n      <th>agemodel<\/th>\n      <th>modelagetype<\/th>\n      <th>isdefault<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"name":"chronologyid","targets":0},{"name":"chronologyname","targets":1},{"name":"agemodel","targets":2},{"name":"modelagetype","targets":3},{"name":"isdefault","targets":4}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

This core has two chronologies. Chronology `1405` is an older model (*COHMAP chron 3*, a weighted cubic regression) in radiocarbon years BP. Chronology `34673` (*Neotoma 2021*) is a Bacon age model in calibrated radiocarbon years BP. We want to build a new one with the function `Bchronology()` from the [`Bchron` package](https://cran.r-project.org/web/packages/Bchron/vignettes/Bchron.html), and then compare the two.

It's worth pointing out the `isdefault` column here. Both of these chronologies are marked as default, because each is the default for its own age type. Neotoma provides the opportunity to link multiple chronologies to a single record. This lets researchers add their chronologies when they publish new studies. For each age type (Radiocarbon years BP, Calendar years BP, &cetera) there is a default chronology that defines the model for the date interpolation. There is also a hierarchy for the default chronologies. By default Neotoma assigns the age model using _calendar years_ the highest priority, then _calibrated radiocarbon years_, then _radiocarbon years_. You can see the order in practice if we look at the content of `get_table("age types")`.

### Extract `chroncontrols`

We're going to use chronology `34673` as our template, because its controls are the ones used for the calibrated ages that `samples()` returns. To generate a new chronology for this record we want to see which chronological control points were used for the record. We will extract all the chroncontrols, filter by the `chronologyid`, and then arrange them by depth:


``` r
# Extract the chronological controls used in the original chronology:
controls <- chroncontrols(heart_lake) %>%
  dplyr::filter(chronologyid == 34673) %>%
  arrange(depth)

controls %>%
  DT::datatable(
    rownames = FALSE,
    options = list(scrollX = "100%")
  )
```

```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-ae95fedf1368051fc26c" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-ae95fedf1368051fc26c">{"x":{"filter":"none","vertical":false,"data":[[728,728,728,728,728,728,728,728,728],[34673,34673,34673,34673,34673,34673,34673,34673,34673],["Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021","Neotoma 2021"],[0,3.5,115.5,208.5,285.5,390.5,405.5,545.5,629.5],[1,7,5,5,5,5,5,5,5],[-28,1010,1520,1730,3275,3770,4960,7500,10245],[-24,1310,1820,1970,3605,4100,5390,7890,10705],[108149,108150,108151,108152,108153,108155,108157,108154,108156],[-26,1160,1670,1850,3440,3935,5175,7695,10475],["Core top","Radiocarbon","Radiocarbon","Radiocarbon","Radiocarbon","Radiocarbon","Radiocarbon","Radiocarbon","Radiocarbon"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>siteid<\/th>\n      <th>chronologyid<\/th>\n      <th>chronologyname<\/th>\n      <th>depth<\/th>\n      <th>thickness<\/th>\n      <th>agelimityounger<\/th>\n      <th>agelimitolder<\/th>\n      <th>chroncontrolid<\/th>\n      <th>chroncontrolage<\/th>\n      <th>chroncontroltype<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","columnDefs":[{"className":"dt-right","targets":[0,1,3,4,5,6,7,8]},{"name":"siteid","targets":0},{"name":"chronologyid","targets":1},{"name":"chronologyname","targets":2},{"name":"depth","targets":3},{"name":"thickness","targets":4},{"name":"agelimityounger","targets":5},{"name":"agelimitolder","targets":6},{"name":"chroncontrolid","targets":7},{"name":"chroncontrolage","targets":8},{"name":"chroncontroltype","targets":9}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

There are 9 controls: a `Core top` and 8 `Radiocarbon` dates, between 3.5 and 629.5 cm. The core top age is in calendar years BP, so its negative age means it is younger than 1950 (the core was collected in 1976). The radiocarbon ages are in *radiocarbon* years BP, so they still need to be calibrated. We could also save this table, edit it in Excel or another spreadsheet program (for example, to add a new date by adding a new row), and read it back in. Here we will use the controls exactly as they were published.

### Extract Depth & Analysis Unit IDs

Next, we extract the `depth`s and `analysisunitid`s from the dataset `samples()`. Pulling in both `depth`s and `analysisunitid`s is important because a single collection unit may have multiple datasets, which may have non-overlapping depth sequences. (Here, the pollen dataset that we left out has its own set of depths.) So, when adding sample ages back to a record we use the `analysisunitid` to make sure we are providing the correct assignment since depth may be specific to a single dataset.


``` r
# Get a two column data.frame with columns depth and analysisunitid.
# Sort the table by depth from top to bottom for "Bchronology"
predict_depths <- samples(heart_lake) %>%
  select(depth, analysisunitid) %>%
  unique() %>%
  arrange(depth)
```

### Building the Age Model

Now we can pass the controls and the sample depths to `Bchronology()`. A few notes on the arguments:

* `ages` and `ageSds`: we assume the distance between `chroncontrolage` and `agelimityounger` is 1 standard deviation. `Bchronology()` wants whole numbers for the standard deviations, so we round them, with a minimum of 1.
* `calCurves`: radiocarbon dates need a calibration curve, here `"intcal20"` (the Northern Hemisphere curve). The core top is already in calendar years, so it gets a `"normal"` distribution instead.
* `predictPositions`: the depths where we want ages. Any sample below the deepest control (629.5 cm) needs `allowOutside = TRUE`, and its age will be extrapolated, with growing uncertainty.

This step takes about 15 seconds. We set the random seed so that everyone gets (nearly) the same answer.


``` r
set.seed(1234)

new_chron <- Bchron::Bchronology(
  ages = controls$chroncontrolage,
  ageSds = pmax(round(abs(controls$agelimityounger - controls$chroncontrolage)), 1),
  calCurves = ifelse(controls$chroncontroltype == "Radiocarbon", "intcal20", "normal"),
  positionThicknesses = controls$thickness,
  positions = controls$depth,
  predictPositions = predict_depths$depth,
  allowOutside = TRUE,
  ids = controls$chroncontrolid
)

# Predict ages at each depth for which we have samples.  Returns a matrix.
newpredictions <- predict(new_chron, predict_depths$depth)
```


``` r
plot(new_chron) +
  ggplot2::labs(
    x = "Age (cal years BP)",
    y = "Depth (cm)"
  )
```

![Age-depth model for Heart Lake, with probability distributions superimposed on the figure at each chronology control depth.](complex_workflow_files/figure-html/chronologyPlot-1.png)

### Creating the New `chronology` and `contact` objects

Given the new chronology, we want to add it to the `sites` object so that it becomes the default for any calls to `samples()`. Our model is built from calibrated radiocarbon dates, so we give it the same age type as the Neotoma 2021 chronology (`Calibrated radiocarbon years BP`). That matters later: `set_default()` switches between chronologies *of the same age type*. To create the metadata for the new chronology, we use `set_chronology()` using the properties from the [`chronology` table in Neotoma](https://open.neotomadb.org/dbschema/tables/chronologies.html):


``` r
# Add information about the people who generated the new chronology:
creators <- c(
  set_contact(
    givennames = "Simon James",
    familyname = "Goring",
    ORCID = "0000-0002-2700-4605"
  ),
  set_contact(
    givennames = "Socorro",
    familyname = "Dominguez Vidaña",
    ORCID = "0000-0002-7926-4935"
  )
)

# Add information about the chronology:
new_chron_heart <- set_chronology(
  agemodel = "Bchron model",
  contact = creators,
  isdefault = TRUE,
  ageboundolder = max(newpredictions),
  ageboundyounger = min(newpredictions),
  dateprepared = Sys.Date(),
  modelagetype = "Calibrated radiocarbon years BP",
  chronologyname = "Workshop example chronology",
  chroncontrols = controls
)

# A short note on how the model was built:
new_chron_heart$notes <- "Bchron::Bchronology() with the radiocarbon controls of chronology 34673, calibrated with IntCal20 (workshop example)."
```

### Adding the `chronology` to the `collectionunit`

Once we've created the chronology we need to apply it back to the collectionunit. We also need to add the predicted dates into the samples for each dataset associated with the collectionunit.

So:

1. we have a collectionunit in `heart_lake` that is accessible at `heart_lake[[1]]$collunits`.
2. We can use the function `add_chronology()`, which takes the chronology object and a `data.frame()` of sample ages.
3. The predicted dates associated with the new chronology need to be transferred to each `samples` object within the `collectionunit`.

This is all bound up in the `add_chronology()` function, which takes the `collectionunit`, modifies it, and returns the newly updated `collectionunit`.


``` r
new_sample_ages <- data.frame(predict_depths,
  age = colMeans(newpredictions),
  ageolder = colMeans(newpredictions) +
    apply(newpredictions, 2, sd),
  ageyounger = colMeans(newpredictions) -
    apply(newpredictions, 2, sd),
  agetype = "Calibrated radiocarbon years BP"
)

heart_lake[[1]]$collunits[[1]] <- add_chronology(
  heart_lake[[1]]$collunits[[1]],
  new_chron_heart,
  new_sample_ages
)
```

With this, we now have the updated collectionunit, and three chronologies in the record:


``` r
chronologies(heart_lake) %>%
  as.data.frame() %>%
  dplyr::select(chronologyid, chronologyname, agemodel, isdefault) %>%
  DT::datatable(
    rownames = FALSE,
    options = list(scrollX = "100%", dom = "t")
  )
```

```{=html}
<div class="datatables html-widget html-fill-item" id="htmlwidget-239fc06c71db79b7fbd1" style="width:100%;height:auto;"></div>
<script type="application/json" data-for="htmlwidget-239fc06c71db79b7fbd1">{"x":{"filter":"none","vertical":false,"data":[["1405","34673","40622563"],["COHMAP chron 3","Neotoma 2021","Workshop example chronology"],["weighted cubic regression","Bacon","Bchron model"],[true,false,true]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>chronologyid<\/th>\n      <th>chronologyname<\/th>\n      <th>agemodel<\/th>\n      <th>isdefault<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"scrollX":"100%","dom":"t","columnDefs":[{"name":"chronologyid","targets":0},{"name":"chronologyname","targets":1},{"name":"agemodel","targets":2},{"name":"isdefault","targets":3}],"order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script>
```

Let's take a look at how this affects the age model overall. To pull the ages from the prior chronology, we use the `set_default()` function to change the default chronology, and then extract ages, depths & analysis units:


``` r
# The new chronology is currently the default chronology.
newages <- samples(heart_lake) %>%
  select(depth, analysisunitid, age) %>%
  unique() %>%
  arrange(depth) %>%
  mutate(agecat = "new")

# Switch back to the Neotoma 2021 (Bacon) chronology:
heart_lake[[1]]$collunits[[1]]$chronologies <- set_default(
  heart_lake[[1]]$collunits[[1]]$chronologies,
  34673
)

plotforages <- samples(heart_lake) %>%
  select(depth, analysisunitid, age) %>%
  unique() %>%
  arrange(depth) %>%
  mutate(agecat = "old") %>%
  bind_rows(newages)
```

And we can look at the difference visually:


``` r
ggplot(plotforages, aes(x = depth, y = age)) +
  geom_path(aes(color = agecat)) +
  geom_point(aes(color = agecat)) +
  theme_bw() +
  xlab("Depth (cm)") +
  ylab("Calendar Years BP (negative = after 1950)")
```

![Differences in age representation between the Neotoma 2021 Bacon chronology (old) and the new Bchron chronology (new).](complex_workflow_files/figure-html/plotAgeDifferences-1.png)

The two models use the same controls, but they do not agree exactly: the ages differ by a few hundred years through most of the core. The biggest difference is in the top 100 cm. The radiocarbon date at 3.5 cm (1160 radiocarbon years BP) is far older than the core top (the core was collected in 1976), and the two age-modelling methods resolve that conflict differently. Below 629.5 cm there is no control, so both models extrapolate and their ages drift apart.

Notice that `set_default()` worked here because the new chronology and the Neotoma 2021 chronology have the same age type. If we had given the new chronology the age type `Calendar years BP`, `samples()` would have kept using it, because Neotoma ranks calendar years above calibrated radiocarbon years.

So we can see the impact of the new chronology on the age model for the record, and we can make choices as to which model we want to use going forward. We can use this approach to create multiple new chronologies for a single record, tuning parameters within `Bchronology()`, or using Bacon and different parameters. Because the `chronology` is an R object we can save the objects for use in future sessions, and associate them with existing records, or we can re-run the models again.

## Summary

From this notebook we have learned how to:

1. Download a single record (the Heart Lake diatom core, using `get_sites()`, `get_datasets()` and `get_downloads()`)
2. Examine the chronologies for the record (using `chronologies()`) and associated chronological controls (using `chroncontrols()`)
3. Create a new chronology for the record (using `Bchronology()` and `set_chronology()`)
4. Add the chronology to the record (using `add_chronology()`)
5. Switch between default chronologies (using `set_default()`)

This approach is focused on a single record, but much of what is done here can be extended to multiple records using functions. We hope it's been helpful!
