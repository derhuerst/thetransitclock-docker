#!/usr/bin/env bash
echo 'THETRANSITCLOCK DOCKER: Create API key.'
# This is to substitute into config file the env values
find /usr/local/transitclock/config/ -type f -exec sed -i s#"POSTGRES_PORT_5432_TCP_ADDR"#"$POSTGRES_PORT_5432_TCP_ADDR"#g {} \;
find /usr/local/transitclock/config/ -type f -exec sed -i s#"POSTGRES_PORT_5432_TCP_PORT"#"$POSTGRES_PORT_5432_TCP_PORT"#g {} \;
find /usr/local/transitclock/config/ -type f -exec sed -i s#"PGPASSWORD"#"$PGPASSWORD"#g {} \;
find /usr/local/transitclock/config/ -type f -exec sed -i s#"AGENCYNAME"#"$AGENCYNAME"#g {} \;
find /usr/local/transitclock/config/ -type f -exec sed -i s#"GTFSRTVEHICLEPOSITIONS"#"$GTFSRTVEHICLEPOSITIONS"#g {} \;

java -cp /usr/local/transitclock/Core.jar org.transitclock.applications.CreateAPIKey -c "/usr/local/transitclock/config/transitclock.properties" -d "Stadtnavi Herrenberg: Digitransit" -e "mail@jannisr.de" -n "Jannis R" -p "123456" -u "http://www.transitclock.org"
