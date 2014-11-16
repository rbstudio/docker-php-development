#!/bin/bash

DEVELOPMENT_PATH=/home/development/
APP_PATH=$DEVELOPMENT_PATH/app
PSQL_PATH=$DEVELOPMENT_PATH/storage/psql
MYSQL_PATH=$DEVELOPMENT_PATH/storage/mysql
MONGO_PATH=$DEVELOPMENT_PATH/storage/mongo

WITH_PSQL=${WITH_PSQL:-no}
WITH_MONGO=${WITH_MONGO:-no}
WITH_MYSQL=${WITH_MYSQL:-no}

VERBOSE=${VERBOSE:-no}
SUPPRESS=""

#Utility functions.

logText () {
    #Will add additional info here
    echo "[DEVENV]"$1
}

enableWatcher () {
    cp $DEVELOPMENT_PATH/config/default/supervisor/all/$1.conf $DEVELOPMENT_PATH/config/default/supervisor/run/$1.conf
}

# Sub commands

bootDevenv () {
    logText "Verbose: "$VERBOSE
    logText "Initiating boot sequence..."
    if [ ! -f /home/development/init_done ]; then
        logText "First time boot, setup environment according to parameters...."
        prepareDevenv
    fi
    if [ $VERBOSE == 'no' ]; then
        logText "Starting supervisor [output suppressed]"
        /usr/bin/supervisord -n -c /home/development/config/default/supervisor/supervisord.conf 1>/dev/null 2>&1
    else
        logText "Starting supervisor"
        /usr/bin/supervisord -n -c /home/development/config/default/supervisor/supervisord.conf
    fi
}

composerInstall () {
    echo "Installing composer deps"
    composer install -o -d $APP_PATH
}

npmInstall () {
    echo "Installing NPM deps"
    cd $APP_PATH && sudo npm install --unsafe-perm
}

# First boot initiation
prepareDevenv () {
    mkdir -p $DEVELOPMENT_PATH/config/default/supervisor/run
    enableWatcher php5-fpm
    enableWatcher nginx

    if [ "$PSQL_HOST" != "no" ]; then
        logText 'Setting up PostgreSql v9.3'
        preparePsql
    fi
}

preparePsql () {
    # Setup the DB
    #We are going to check if the storage dir already defines a DB, if
    #so, skip
    if [ ! -f $PSQL_PATH/PG_VERSION ]; then
        logText "Initializing new Postgres DB setup."
        chown -R postgres:postgres /home/development/storage/psql
        if [ $VERBOSE == 'no' ]; then
            logText "Initializing new Postgres DB [output suppressed]"
            sudo -u postgres /usr/lib/postgresql/9.3/bin/initdb -E utf8 --locale en_US.UTF-8 -D $PSQL_PATH  1>/dev/null 2>&1
        else
            logText "Initializing new Postgres DB"
            sudo -u postgres /usr/lib/postgresql/9.3/bin/initdb -E utf8 --locale en_US.UTF-8 -D $PSQL_PATH
        fi

        #Configure for usage as local devenv
        sed -i -e "s/#listen_addresses\s*=\s*'localhost'/listen_addresses = '*'/g" $PSQL_PATH/postgresql.conf
        sed -i -e "s/data_directory\s*=.*$/data_directory = '\/home\/development\/storage\/psql'/g" $PSQL_PATH/postgresql.conf
        sed -i -e "s/#\s*IPv4 local connections:/#Allow all IPv4 interfaces/g" $PSQL_PATH/pg_hba.conf
        sed -i -e "s/127.0.0.1\/32.*/0.0.0.0\/0 trust/g" $PSQL_PATH/pg_hba.conf
        mkdir -p $PSQL_PATH/pg_log
    else
        logText "Existing Postgres DB found...skipping creation."
    fi

    chown -R postgres:postgres /home/development/storage/psql
    chmod -R 700 /home/development/storage/psql # Mandatory access level

    # Add to supervisor
    enableWatcher psql
}

case "$1" in
    devenv:boot)
        bootDevenv
        ;;
    devenv:deps-install)
        composerInstall
        npmInstall
        ;;
    devenv:deps-clean)
        composerClean
        npmClean
        ;;
esac
