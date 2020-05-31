#!/bin/bash

# Exit on error
set -e

# Load water and land polygons
git clone https://github.com/gma2th/pgosmdata.git
cd pgosmdata && make all && cd .. && rm -rf pgosmdata

# Load ais data
psql "$DATABASE_URL" -f sql/import.sql

# Prepare ais data
psql "$DATABASE_URL" -f sql/prepare.sql

# Create geopackage
ogr2ogr -f "GPKG" data/aisdk_30min.gpkg PG:"$DATABASE_URL" "aisdk_30min"
