PHP Development Environment in a docker container
===========

# Contents

* [Supervisor v3.0b2-1](http://supervisord.org/)
* [Nginx v1.6,2](http://nginx.org/en/CHANGES-1.6)
* [PostgreSQL v9.4 (rc1)](http://www.postgresql.org/about/news/1555/)
* [PHP v5.6.2](http://php.net/ChangeLog-5.php#5.6.2)
* [Phalcon v1.3.4](http://phalconphp.com/en/)
* [Ruby 2.1.3 in RVM with Bundler](https://www.ruby-lang.org/en/news/2014/09/19/ruby-2-1-3-is-released/)
* [Composer](https://getcomposer.org/)
* [NPM v1.4.28](https://www.npmjs.org/)
* [Gulp.js](http://gulpjs.com/)

# Container commands & options

* Commands

  * **devenv:help** - Display the help message.
  * **devenv:run** - Run the nginx server on the app folder.
  * **devenv:deps** - Access to *install* && *clean* subcommands for composer/npm dependencies.
  * **devenv:tools** - Access to *gulp*, *npm* & *composer* sub commands.

* Environment parameters

  * **WITH_PSQL** - *yes/no* Use the built in PSQL server.
    * `-e WITH_PSQL=yes`
  * **VERBOSE** - *yes/no* Additional logging.
    * `-e VERBOSE=yes`
* Volumes

  * **/home/development/app** - (*mandatory*) Mount the application folder here.
    * `-v <path>:/home/development/app`
  * **/home/development/config/custom/sites-enabled** - (*mandatory*) Mount nginx config files for the application.
  * **/home/development/storage/psql** - Persistant storage for the PSQL database.
  * **/home/development/logs** - Access to nginx, php5-fpm & psql logs.
  * **/home/development/storage/files** - File storage for file cache etc.
  * **/home/development/storage/mongo** - (*todo*) Add mongo & persistant storage.
  * **/home/development/storage/mysql** - (*todo*) Add mysql & persistant storage.

# Usage examples

1. Display the help message

`docker run --rm -it redbuffstudio/docker-php-development:beta`

2. Run a php application

```bash
docker run --rm -it -p 80:80 -p 5432:5432 \
-v <path-to-app>:/home/development/app \
-v <path-to-psql-storage>:/home/development/storage/psql \
-v <path-to-logs>:/home/development/logs \
-v <path-to-configs>:/home/development/config/custom/sites-enabled \
-e WITH_PSQL=yes -e VERBOSE=yes \
redbuffstudio/docker-php-development:beta devenv:run
```

3. Start the gulp watch process (if setup in the Gulpfile.js)

```bash
docker run --rm -it \
-v <path-to-app>:/home/development/app \
redbuffstudio/docker-php-development:beta devenv:tools gulp watch
```

# License

* Copyright 2014 [Red Buff Studio LTD](http://redbuffstudio.com)
* Distributed under the MIT License (hereby included)
