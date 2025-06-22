#!/usr/bin/bash
set -eo pipefail

BASEDIR=$(dirname $0)
DATADIR=$BASEDIR/../data

curl -sSL 'https://data.nantesmetropole.fr/api/explore/v2.1/catalog/datasets/244400404_quartiers-communes-nantes-metropole/exports/parquet' -o $DATADIR/open-data-naoned-quartiers.parquet
