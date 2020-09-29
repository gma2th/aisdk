# AISDK

## Description

This is a demo project where we process and analyze a sample of AIS data from the [Danish Marithim Authority](https://www.dma.dk/SikkerhedTilSoes/Sejladsinformation/AIS/Sider/default.aspx).
The aim is to predict vessels that were potentially engaged in illegal fishing.

The raw data as been preprocessed using postgres, postgis, and timescaledb. We performed the following:

- Remove positions with incorrect coordinates
- Keep only one position every thirty minutes using timescaledb
- Compute a fishing score for each vessel based on [Global Fish Watch heuristic model](https://github.com/GlobalFishingWatch/vessel-scoring/blob/master/notebooks/Model-Descriptions.ipynb)
- Calculate the distance from land using land polygon from [pgosmdata](https://github.com/gma2th/pgosmdata) and postgis nearest neighbor algorithm
- Create fishing zones with dbscan algorithm

Here's is an overview of the data in QGIS:

- The yellow points are vessels that report "Engaged in fishing" as their navigational status
- The red points are vessels that don't report "Engaged in fishing" as their navigational status but have a fishing score above 0.5 (out of 1)
- The yellow polygons are fishing zone we computed using postgis dbscan algorithm on positions of vessels that reported "Engaged in fishing" as their navigational status

![Overview of ais data](data/aisdk.png)

We also perform some data analysis in a jupyter notebook:

- Identify ships with the longest self-reported fishing time
- Identify ships with the longest fishing time that does not report fishing in their navigational status
- Identify the longest trip of the day

You may run the analysis in a MyBinder notebook, no installation required: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/gma2th/aisdk/master?filepath=analysis.ipynb)

## Next Steps

- The Global Fish Watch heuristic model was used in this project to predict if vessels are fishing. But we could go further by using the logistic model that could remove some false positives.
- Perform in-depth track analysis to find gaps or AIS spoofing in messages received.

## Installation

```bash
git clone https://github.com/gma2th/aisdk.git
cd aisdk
```

### Analysis

Check out the jupyter notebook with:

```bash
conda env create -f environment.yml
jupyter notebook
```

### Preprocessing

#### Requirements

It has been tested with:

- Postgres 12.2
- Postgis 3.0.1
- Timescaledb 1.7.1

You will need at least postgresql-client and ogr2ogr installed on your local machine.
You will need a postgres database with the extension postgis and timescaledb. You can refer to [TimescaleDB Installation Guide](https://docs.timescale.com/latest/getting-started/installation/), you can install it on your local machine on using docker.

#### Download data

Download AIS data from the [Danish Marithim Authority](https://www.dma.dk/SikkerhedTilSoes/Sejladsinformation/AIS/Sider/default.aspx) and place it under the data/ directory.

#### Run

```bash
createdb aisdk
source .env.example  # Edit if necessary
./prepare.sql
```

It will output the result as a geopackage in `data/aisdk_30min.gpkg`.
