#!/bin/bash

#Terminal goodies with tput
## Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CCLOSE=$(tput sgr0)

##Bold
BOLD=$(tput smso)
CBOLD=$(tput rmso)

#Container paths
DEVELOPMENT_PATH=/home/development
APP_PATH=$DEVELOPMENT_PATH/app
PSQL_PATH=$DEVELOPMENT_PATH/storage/psql
MYSQL_PATH=$DEVELOPMENT_PATH/storage/mysql
MONGO_PATH=$DEVELOPMENT_PATH/storage/mongo
FILE_PATH=$DEVELOPMENT_PATH/storage/files

#Environment options for different supervisor monitoring.
WITH_PSQL=${WITH_PSQL:-no}
WITH_MONGO=${WITH_MONGO:-no}
WITH_MYSQL=${WITH_MYSQL:-no}

#Enable verbosity
VERBOSE=${VERBOSE:-no}

#Fix path for rvm
PATH=$PATH:/usr/local/rvm/gems/ruby-2.1.3/bin:/usr/local/rvm/rubies/ruby-2.1.3/bin

#Utility functions.
logText () {
    if [ -n "$2" ]; then
        echo "${BLUE}[DEVENV]:${CCLOSE}${2}${1}${CCLOSE}"
    else
        echo "${BLUE}[DEVENV]:${CCLOSE}${1}"
    fi
}

#Copy a supervisor conf file to the path that determines what is run
#on process tart
enableWatcher () {
    cp $DEVELOPMENT_PATH/config/default/supervisor/all/$1.conf $DEVELOPMENT_PATH/config/default/supervisor/run/$1.conf
}

#Display the help message
showHelp () {
    logText "Help" $GREEN
    logText " -- Available commands:"
    logText " -- devenv:help" $GREEN
    logText " ---- Display this message."
    logText " -- devenv:run" $GREEN
    logText " ---- Run the application."
    logText " -- devenv:deps" $GREEN
    logText " ---- Subcommands (e.g. \"devenv:deps install\")" $BLUE
    logText " ---- install" $GREEN
    logText " ------ Install composer & npm dependencies."
    logText " ---- clean" $GREEN
    logText " ------ Remove DEFAULT npm/composer folders."
    logText " -- devenv:tools (composer, gulp, npm, phalcon)" $GREEN
    logText " ---- Subcommands (e.g. \"devenv:tools gulp watch\")" $BLUE
    logText " ---- composer" $GREEN
    logText " ------ Execute a composer command."
    logText " ---- gulp" $GREEN
    logText " ------ Execute a command from your Gulpfile.js."
    logText " ---- npm" $GREEN
    logText " ------ Execute a npm command."
    logText " ---- phalcon" $GREEN
    logText " ------ Execute a phalcon command."
}

# Execute Application
# CMD devenv:run
runApplication () {
    logText "Verbose: ${VERBOSE}" $YELLOW
    logText "Initiating boot sequence..." $YELLOW

    if [ ! -f /home/development/init_done ]; then
        logText "First time boot, setup environment according to parameters...." $GREEN
        setupEnvironment
    fi

    if [ $VERBOSE == 'no' ]; then
        logText "Starting supervisor [output suppressed]" $GREEN
        eval `ssh-agent -s` && /usr/bin/supervisord -n -c /home/development/config/default/supervisor/supervisord.conf 1>/dev/null 2>&1
    else
        logText "Starting supervisor [verbose mode]" $GREEN
        eval `ssh-agent -s` && /usr/bin/supervisord -n -c /home/development/config/default/supervisor/supervisord.conf
    fi
}

# First boot initiation
setupEnvironment () {
    mkdir -p $DEVELOPMENT_PATH/config/default/supervisor/run
    enableWatcher php5-fpm
    enableWatcher nginx

    if [ "$PSQL_HOST" != "no" ]; then
        logText 'Setting up PostgreSql v9.4'
        preparePsql
    fi
}

preparePsql () {
    # Setup the DB
    #We are going to check if the storage dir already defines a DB, if
    #so, skip
    if [ ! -f $PSQL_PATH/PG_VERSION ]; then
        logText "Initializing new Postgres DB setup." $GREEN
        chown -R postgres:postgres /home/development/storage/psql
        if [ $VERBOSE == 'no' ]; then
            logText "Initializing new Postgres DB [output suppressed]" $GREEN
            sudo -u postgres /usr/lib/postgresql/9.4/bin/initdb -E utf8 --locale en_US.UTF-8 -D $PSQL_PATH  1>/dev/null 2>&1
        else
            logText "Initializing new Postgres DB" $GREEN
            sudo -u postgres /usr/lib/postgresql/9.4/bin/initdb -E utf8 --locale en_US.UTF-8 -D $PSQL_PATH
        fi

        #Configure for usage as local devenv
        sed -i -e "s/#listen_addresses\s*=\s*'localhost'/listen_addresses = '*'/g" $PSQL_PATH/postgresql.conf
        sed -i -e "s/data_directory\s*=.*$/data_directory = '\/home\/development\/storage\/psql'/g" $PSQL_PATH/postgresql.conf
        sed -i -e "s/#\s*IPv4 local connections:/#Allow all IPv4 interfaces/g" $PSQL_PATH/pg_hba.conf
        sed -i -e "s/127.0.0.1\/32.*/0.0.0.0\/0 trust/g" $PSQL_PATH/pg_hba.conf
        mkdir -p $PSQL_PATH/pg_log
    else
        logText "Existing Postgres DB found...skipping creation." $GREEN
    fi

    chown -R postgres:postgres /home/development/storage/psql
    chmod -R 700 /home/development/storage/psql # Mandatory access level

    # Add to supervisor
    enableWatcher psql
}

#Deps installation
# CMD This is used only internaly
bundleRun () {
    logText "Executing \"bundle $1\"" $GREEN
    BUNDLE_GEMFILE=$APP_PATH/Gemfile bundle $1
}

phalconRun () {
    logText "Executing \"phalcon $1 $2 $3\"" $GREEN
    phalcon $1 $2 $3
}

# CMD devenv:composer <cmd>
composerRun () {
    logText "Executing \"composer $1 -o -d $APP_PATH\"" $GREEN
    composer $1 -o -d $APP_PATH --prefer-source --no-interaction
}

#CMD Internal, removes default composer folder.
composerClean () {
    logText "Trying to remove vendor folder at default location ${APP_PATH}/vendor" $GREEN
    rm -rf $APP_PATH/vendor
}

npmClean () {
    logText "Trying to remove vendor folder at default location ${APP_PATH}/node_modules" $GREEN
    rm -rf $APP_PATH/node_modules
}

# CMD devenv:npm <cmd>
npmRun () {
    logText "Executing \"npm $1 $2 $3\"" $GREEN
    cd $APP_PATH && npm $1 $2 $3 --unsafe-perm
}

# CMD devenv:gulp <cmd>
gulpRun () {
    logText "Satisfying gulp dependencies..." $GREEN
    bundleRun install
    logText "Executing \"gulp $1 $2 $3\"" $GREEN
    cd $APP_PATH && gulp $1 $2 $3
}

case "$1" in
    devenv:help)
        showHelp
        ;;
    devenv:run)
        runApplication
        ;;
    devenv:deps)
        case "$2" in
            install)
                composerRun "install"
                npmRun "install"
                ;;
            clean)
                composerClean
                npmClean
                ;;
            *)
                logText "Unknown dependency command. Available: install\clean" $RED
                ;;
        esac
        ;;
    devenv:tools)
        case "$2" in
            composer)
                composerRun "$3" "$4" "$5"
                ;;
            gulp)
                gulpRun "$3" "$4" "$5"
                ;;
            npm)
                npmRun "$3" "$4" "$5"
                ;;
            phalcon)
                phalconRun "$3" "$4" "$5"
                ;;
        esac
        ;;
    *)
        logText "Unrecognized command: ${1}" $RED
        ;;
esac
