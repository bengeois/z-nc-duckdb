#!/usr/bin/bash
set -eo pipefail

BASEDIR=$(dirname $0)
DATADIR=$BASEDIR/../data

curl -sSL 'https://data.nantesmetropole.fr/explore/dataset/244400404_transports_commun_naolib_nantes_metropole_gtfs/files/0cc0469a72de54ee045cb66d1a21de9e/download/' -o $DATADIR/open-data-naolib.zip
unzip $DATADIR/open-data-naolib.zip -d $DATADIR/open-data-naolib

duckdb $DATADIR/open-data-naolib.duckdb -c """
create or replace table agency as (from read_csv('$DATADIR/open-data-naolib/agency.txt'));
create or replace table calendar as (from read_csv('$DATADIR/open-data-naolib/calendar.txt'));
create or replace table routes as (from read_csv('$DATADIR/open-data-naolib/routes.txt'));
create or replace table shapes as (from read_csv('$DATADIR/open-data-naolib/shapes.txt'));
create or replace table stops as (from read_csv('$DATADIR/open-data-naolib/stops.txt'));
create or replace table stop_times as (from read_csv('$DATADIR/open-data-naolib/stop_times.txt'));
create or replace table trips as (from read_csv('$DATADIR/open-data-naolib/trips.txt'));
"""

rm $DATADIR/open-data-naolib.zip
# rm -r $DATADIR/open-data-naolib # These files are needed for the validation-generator part

duckdb $DATADIR/open-data-naolib.duckdb -c "show all tables;"
