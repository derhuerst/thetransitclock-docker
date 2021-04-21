FROM maven:3.6-jdk-8
LABEL org.opencontainers.image.authors="Jannis R <mail@jannisr.de>"

ARG AGENCYID="1"
ARG AGENCYNAME
ARG GTFS_URL
ARG GTFSRTVEHICLEPOSITIONS
ARG TRANSITCLOCK_PROPERTIES="config/transitclock.properties"

ENV AGENCYID ${AGENCYID}
ENV AGENCYNAME ${AGENCYNAME}
ENV GTFS_URL ${GTFS_URL}
ENV GTFSRTVEHICLEPOSITIONS ${GTFSRTVEHICLEPOSITIONS}
ENV TRANSITCLOCK_PROPERTIES ${TRANSITCLOCK_PROPERTIES}

ENV TRANSITCLOCK_CORE /transitclock-core

RUN apt-get update \
	&& apt-get install -y postgresql-client \
	&& apt-get install -y git-core

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.53
ENV TOMCAT_TGZ_URL https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*

EXPOSE 8080


# Install json parser so we can read API key for CreateAPIKey output
RUN wget -q 'https://stedolan.github.io/jq/download/linux64/jq' -O /usr/local/bin/jq && chmod +x /usr/local/bin/jq

# todo: is this necessary?
RUN mkdir -p /usr/local/transitclock/{db,config,logs,cache,data,test/config}

WORKDIR /usr/local/transitclock

RUN  curl -s https://api.github.com/repos/TheTransitClock/transitime/releases/latest | jq -r ".assets[].browser_download_url" | grep 'Core.jar\|api.war\|web.war' | xargs -L1 wget -q

# Deploy API which talks to core using RMI calls.
RUN mv api.war  /usr/local/tomcat/webapps

# Deploy webapp which is a UI based on the API.
RUN mv web.war  /usr/local/tomcat/webapps

# Scripts required to start transiTime.
ADD bin /usr/local/transitclock/bin

ENV PATH="/usr/local/transitclock/bin:${PATH}"

# This is a way to copy in test data to run a regression test.
# ADD data/avl.csv /usr/local/transitclock/data/avl.csv
# ADD data/gtfs_hart_old.zip /usr/local/transitclock/data/gtfs_hart_old.zip

RUN \
	sed -i 's/\r//' /usr/local/transitclock/bin/*.sh &&\
 	chmod 777 /usr/local/transitclock/bin/*.sh

ADD config/postgres_hibernate.cfg.xml /usr/local/transitclock/config/hibernate.cfg.xml
ADD ${TRANSITCLOCK_PROPERTIES} /usr/local/transitclock/config/transitclock.properties

# This adds the transitime configs to test.
ADD config/test/* /usr/local/transitclock/config/test/

EXPOSE 8080

CMD ["/start_transitclock.sh"]
