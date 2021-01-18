FROM php:7-apache
LABEL maintainer="Lukas Vanagas"

ARG TIMEZONE="Europe/Copenhagen"

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Libraries for container's ecosystem
    git-core zsh supervisor cron vim \
    # Libraries for PHP 
    unzip libmcrypt-dev libpcre3-dev libxml2-dev libzip-dev libpng-dev libjpeg-dev libc-client-dev libkrb5-dev 

# Install PHP Extensions
RUN pecl install -o -f apcu && \
    docker-php-ext-enable apcu && \
    docker-php-ext-configure gd --with-jpeg && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install -j$(nproc) imap pdo_mysql bcmath xmlrpc zip pcntl intl opcache gd exif sockets mysqli && \
    # 
    # Clean caches and remove temp files
    rm -rf /tmp/pear && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 


# Set upsteam repo
ENV GIT_REPO=https://github.com/osTicket/osTicket

# Scripts
COPY bin /bin
COPY conf /conf
COPY conf/msmtp /etc/msmtp.default

# Install Oh-my-zsh terminal
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    # Append shell configuration contents from terminal.conf
    cat /conf/terminal.conf >> /root/.zshrc

# Conf files
RUN touch /etc/msmtp /etc/osticket.secret.txt /etc/cron.d/osticket && \
    chown www-data:www-data /etc/msmtp /etc/osticket.secret.txt /etc/cron.d/osticket && \
    chown root:www-data /bin/vendor && chmod 770 /bin/vendor && \
    ln -fs /conf/php.ini "$PHP_INI_DIR/conf.d/custom.ini" && \
    ln -fs /conf/supervisord.conf /etc/supervisor/conf.d/custom.conf && \
    echo "date.timezone=$TIMEZONE" >> "$PHP_INI_DIR/conf.d/custom.ini" && \
    chmod +x /bin/vendor

EXPOSE 80
VOLUME /var/www
ENTRYPOINT ["entrypoint"]
