# e4Cash DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Middleware Wildfly
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) linuxx64_12201_database.zip
#     Download Oracle Database 12c Release 12 Standard Edition 2 for Linux x64
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build --build-arg DB_HOST=localhost --build-arg DB_NAME=test --build-arg DB_USER=test --build-arg DB_PASS=testPassword .
#
# Pull base image
# ---------------
FROM ubuntu:16.04

# Maintener
MAINTAINER Jose A. Schmucke <jose.schmucke@ab4cus.com>

# Enviroment

ENV PG_APP_HOME="/opt/postgresql" \
    PG_VERSION=10 \
    PG_USER=postgres \
    PG_HOME=/var/lib/postgresql \
    PG_RUNDIR=/run/postgresql \
    PG_LOGDIR=/var/log/postgresql \
    PG_CERTDIR=/etc/postgresql/certs

ENV PG_BINDIR=/usr/lib/postgresql/${PG_VERSION}/bin \
    PG_DATADIR=${PG_HOME}/${PG_VERSION}/main

ENV PATH ${PATH}:${JAVA_HOME}/bin
ENV POSTGRESQL_VERSION 9.4-1201-jdbc41

ARG DB_HOST=postgresql
ARG DB_NAME=e4cash
ARG DB_USER=e4cash
ARG DB_PASS=e41234

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL's repository. It contains the most recent stable release
#     of PostgreSQL, ``9.3``.
#RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
#     of PostgreSQL, ``10.4``.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" > /etc/apt/sources.list.d/postgresql.list

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 10.4
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
#RUN apt-get update && apt-get install -y -f python-software-properties software-properties-common postgresql-10
# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -fy acl sudo \
 	build-dep build-essential \
# 	libpulse0 libpq5 libk5crypto3 libgssapi-krb5-2=1.13.2+dfsg-5 libkrb5-3=1.13.2+dfsg-5 sysstat \
    postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} \
 && ln -sf ${PG_DATADIR}/postgresql.conf /etc/postgresql/${PG_VERSION}/main/postgresql.conf \
 && ln -sf ${PG_DATADIR}/pg_hba.conf /etc/postgresql/${PG_VERSION}/main/pg_hba.conf \
 && ln -sf ${PG_DATADIR}/pg_ident.conf /etc/postgresql/${PG_VERSION}/main/pg_ident.conf \
 && rm -rf ${PG_HOME} \
 && rm -rf /var/lib/apt/lists/*


COPY --from=add-apt-repositories /etc/apt/trusted.gpg /etc/apt/trusted.gpg

COPY --from=add-apt-repositories /etc/apt/sources.list /etc/apt/sources.list

# Run the rest of the commands as the ``postgres`` user created by the ``postgres-10.4`` package when it was ``apt-get installed``
USER ${PG_USER}

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

WORKDIR ${PG_HOME}

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf"]
