FROM ubuntu:14.04
MAINTAINER Boyan Bonev <b.bonev@redbuffstudio.com>

#Setup container environment parameters
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No

#Configure locale.
RUN locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#Prepare the image
RUN apt-get -y update


#=====General utilities=====#

RUN apt-get install -y -q python-software-properties software-properties-common bash-completion wget nano \
curl libcurl3 libcurl3-dev build-essential libpcre3-dev expect


# Install VCS
RUN apt-get install -y -q git subversion
#=====END=====#

#=====NGINX 1.6.2 Installation=====#

RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get -y update
RUN apt-get install -y nginx

#=====END 1.6.2 Installation=====#

#=====POSTGRES 9.4 Installation=====#
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.4" >> /etc/apt/sources.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get -y update
RUN apt-get install -y postgresql-9.4 postgresql-contrib-9.4 postgresql-common
#=====END 9.4 Installation=====#

#=====PHP 5.6.2 Installation=====#

RUN echo "deb http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu trusty main" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key E5267A6C
RUN apt-get -y update
RUN apt-get install -y -q php5-cli php5-fpm php5-dev php5-mysql php5-pgsql php5-mongo php5-curl php5-gd php5-intl php5-imagick php5-mcrypt php5-memcache php5-xmlrpc php5-xsl
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Edit PHP config
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ UTC/g' /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;listen.mode\s*=\s*0660/listen.mode = 0666/g" /etc/php5/fpm/pool.d/www.conf

#Install phalcon
RUN git clone git://github.com/phalcon/cphalcon.git /tmp/cphalcon
RUN cd /tmp/cphalcon/build && git checkout 1.3.4
RUN cd /tmp/cphalcon/build && ./install
RUN echo "extension=phalcon.so" > /etc/php5/mods-available/phalcon.ini
RUN php5enmod phalcon

#Install phalcon devtools
RUN git clone https://github.com/phalcon/phalcon-devtools.git /usr/local/lib/phalcon-devtools
RUN ln -s /usr/local/lib/phalcon-devtools/phalcon.php /usr/bin/phalcon
RUN chmod +x /usr/bin/phalcon
#=====END=====#

#=====Ruby 2.1.3 Installation (with RVM)=====#
RUN apt-get install -y -q libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.1.3"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

#=====END=====#

#=====PHP REDIS DRIVER=====#
RUN apt-get install php5-redis

#=====Node v5 install=====#

RUN curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
RUN apt-get install -y -q nodejs

#FIXME
#We won't install any packages, just use napa for now
RUN npm install -g napa --save-dev
RUN npm install -g gulp
#=====END=====#

#=====Supervisor Installation=====#

RUN apt-get install -y supervisor=3.0b2-1

#=====END=====#

#=====Assets, shell, environment=====#

ADD ./config /home/development/config/default
ADD ./bin /home/development/bin
RUN chmod 755 /home/development/bin/*
#=====END=====#

RUN mkdir -p /home/development/storage/mongo
RUN mkdir -p /home/development/storage/psql
RUN mkdir -p /home/development/storage/mysql
RUN mkdir -p /home/development/logs
RUN mkdir -p /home/development/config/custom/sites-enabled
RUN mkdir -p /home/development/app

#Storage volumes
VOLUME ["/home/development/storage/mongo"]
VOLUME ["/home/development/storage/psql"]
VOLUME ["/home/development/storage/mysql"]
VOLUME ["/home/development/storage/files"]

#Logs volume
VOLUME ["/home/development/logs"]

#Config volumes
VOLUME ["/home/development/config/custom/sites-enabled"]

#Application volume
VOLUME ["/home/development/app"]

EXPOSE 80

ENTRYPOINT ["/home/development/bin/boot.sh"]

CMD ["devenv:help"]
