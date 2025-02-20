#!/bin/sh
set -e
set -x
set -o pipefail

export PGPASSWORD=transitclock

docker stop transitclock-db
docker stop transitclock-server-instance

docker rm transitclock-db
docker rm transitclock-server-instance

docker rmi transitclock-server

docker build --no-cache -t transitclock-server \
--build-arg TRANSITCLOCK_PROPERTIES="config/transitclock.properties" \
--build-arg AGENCYID="1" \
--build-arg AGENCYNAME="herrenberg" \
--build-arg GTFS_URL="https://www.openvvs.de/dataset/e66f03e4-79f2-41d0-90f1-166ca609e491/resource/bfbb59c7-767c-4bca-bbb2-d8d32a3e0378/download/google_transit.zip" \
--build-arg GTFSRTVEHICLEPOSITIONS="http://api.localhost:5000/gtfs-rt-vehicle-positions.pbf" .

docker run --name transitclock-db -p 5432:5432 -e POSTGRES_PASSWORD=$PGPASSWORD -d postgres:9

# check if the PostgreSQL is accessible
docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD -v ~/logs:/usr/local/transitclock/logs/ transitclock-server psql -c 'select 1'

docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD -v ~/logs:/usr/local/transitclock/logs/ transitclock-server create_tables.sh

docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD -v ~/logs:/usr/local/transitclock/logs/ transitclock-server import_gtfs.sh

docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD -v ~/logs:/usr/local/transitclock/logs/ transitclock-server create_api_key.sh

docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD -v ~/logs:/usr/local/transitclock/logs/ transitclock-server create_webagency.sh

#docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD transitclock-server ./import_avl.sh

#docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD transitclock-server ./process_avl.sh

docker run --name transitclock-server-instance --rm --link transitclock-db:postgres -e PGPASSWORD=$PGPASSWORD  -v ~/logs:/usr/local/transitclock/logs/ -v ~/ehcache:/usr/local/transitclock/cache/ -p 8080:8080 -it transitclock-server start_transitclock.sh
