ARG PHP_MAJOR="8.0"
ARG RUNMODE=fpm
FROM registry.aliyuncs.com/fooz79/php-with-ext:${PHP_MAJOR}-${RUNMODE}

ARG PHP_MAJOR="8.0"
ARG RUNMODE=fpm

RUN set -ex apk update --no-cache && apk upgrade --no-cache && apk add --no-cache \
    bash \
    bind-tools \
    busybox-extras \
    busybox-initscripts \
    git \
    git-bash-completion \
    htop \
    logrotate \
    mariadb-connector-c \
    mongodb-tools \
    mysql-client \
    nginx \
    openrc \
    procps \
    redis \
    screen \
    subversion \
    supervisor \
    tini \
    tree \
    vim \
    wget && \
    apk add --no-cache --virtual .build-deps tzdata && \
    # Disable getty's
    sed -i 's/^\(tty\d\:\:\)/#\1/g' /etc/inittab && \
    # Change rc.conf
    sed -i \
        # Change subsystem type to "docker"
        -e 's/#rc_sys=".*"/rc_sys="docker"/g' \
        # Allow all variables through
        -e 's/#rc_env_allow=".*"/rc_env_allow="\*"/g' \
        # Start crashed services
        -e 's/#rc_crashed_stop=.*/rc_crashed_stop=NO/g' \
        -e 's/#rc_crashed_start=.*/rc_crashed_start=YES/g' \
        # Define extra dependencies for services
        -e 's/#rc_provide=".*"/rc_provide="loopback net"/g' \
        /etc/rc.conf && \
    # Remove unnecessary services
    rm -f \
        /etc/init.d/hwdrivers \
        /etc/init.d/hwclock \
        /etc/init.d/hwdrivers \
        /etc/init.d/modules \
        /etc/init.d/modules-load \
        /etc/init.d/modloop \
        /etc/init.d/machine-id && \
    # Disable cgroups
    sed -i 's/\tcgroup_add_service/\t#cgroup_add_service/g' /lib/rc/sh/openrc-run.sh && \
    sed -i 's/VSERVER/DOCKER/Ig' /lib/rc/sh/init.sh && \
    # Timezone
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && \
    # Bashrc
    echo "PS1='\033[1;33m\h \033[1;34m[\w] \033[1;35m\D{%D %T}\n\[\033[1;36m\]\u@\l \[\033[00m\]\$ '" > /root/.bashrc && \
    echo "alias ll='ls -l'" >> /root/.bashrc && \
    apk del .build-deps && \
    # OpenRC service
    rc-update add crond && \
    rc-update add supervisord && \
    rc-update add nginx && \
    rc-update add redis && \
    # WorkDir
    rm -f /etc/nginx/conf.d/default.conf && \
    mkdir -p /data/nginx/wwwlogs /data/nginx/wwwroot && \
    mkdir /var/log/supervisor && \
    mkdir /etc/supervisor.d && \
    mkdir -p /etc/nginx/default.d && \
    chown nobody. -R /data/nginx/wwwlogs /var/lib/nginx/tmp

EXPOSE 80 6379

CMD ["/sbin/init"]

VOLUME [ "/data" ]

