#!/bin/bash

set -e
set -x

export PG_ADMIN_PASSWORD=admin
export PG_ROLE=role
export PG_PASSWORD=password

function userdata() {
        exec 2>&1

    echo "+++ POSTGRESQL CREATE"
    su - postgres -c "psql -c \"ALTER ROLE postgres WITH UNENCRYPTED PASSWORD '$PG_ADMIN_PASSWORD';\""
    su - postgres -c "psql -c \"CREATE ROLE $PG_ROLE;\""
    su - postgres -c "psql -c \"ALTER ROLE $PG_ROLE WITH LOGIN UNENCRYPTED PASSWORD '$PG_PASSWORD' NOSUPERUSER NOCREATEDB NOCREATEROLE;\""
    su - postgres -c "psql -c \"CREATE DATABASE $PG_ROLE OWNER $PG_ROLE;\""
    su - postgres -c "psql -c \"REVOKE ALL ON DATABASE $PG_ROLE FROM PUBLIC;\""
    su - postgres -c "psql -c \"GRANT CONNECT ON DATABASE $PG_ROLE TO $PG_ROLE;\""
    su - postgres -c "psql -c \"GRANT ALL ON DATABASE $PG_ROLE TO $PG_ROLE;\""

}

userdata > /var/log/userdata.log

