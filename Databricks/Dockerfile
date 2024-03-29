# Copyright (c) 2022-2023, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

############# 
# Combine all below Dockerfiles together:
# https://github.com/databricks/containers/blob/master/ubuntu/gpu/cuda-11/base/Dockerfile
# https://github.com/databricks/containers/blob/master/ubuntu/minimal/Dockerfile
# https://github.com/databricks/containers/blob/master/ubuntu/python/Dockerfile
# https://github.com/databricks/containers/blob/master/ubuntu/dbfsfuse/Dockerfile
# https://github.com/databricks/containers/blob/master/ubuntu/standard/Dockerfile
# https://github.com/databricks/containers/blob/master/experimental/ubuntu/ganglia/Dockerfile
# https://github.com/dayananddevarapalli/containers/blob/main/webterminal/Dockerfile
#############
ARG CUDA_VERSION=11.8.0
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu20.04 as base

ARG CUDA_PKG_VERSION=11-8

#############
# Install all needed libs
#############

RUN set -ex && \ 
    cd /etc/apt/sources.list.d && \
    mv cuda.list cuda.list.disabled && \
    apt-get -y update && \
    apt-get -y install wget && \
    wget -qO - https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/3bf863cc.pub | apt-key add - && \
    cd /etc/apt/sources.list.d && \
    mv cuda.list.disabled cuda.list && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get -y install python3.8 virtualenv python3-filelock libcairo2 cuda-cupti-${CUDA_PKG_VERSION} \
               cuda-toolkit-${CUDA_PKG_VERSION}-config-common cuda-toolkit-11-config-common cuda-toolkit-config-common \
               openjdk-8-jdk-headless iproute2 bash sudo coreutils procps gpg fuse openssh-server && \
    apt-get -y install cuda-cudart-dev-${CUDA_PKG_VERSION} cuda-cupti-dev-${CUDA_PKG_VERSION} cuda-driver-dev-${CUDA_PKG_VERSION} \
               cuda-nvcc-${CUDA_PKG_VERSION} cuda-thrust-${CUDA_PKG_VERSION} cuda-toolkit-${CUDA_PKG_VERSION}-config-common cuda-toolkit-11-config-common \
               cuda-toolkit-config-common python3.8-dev libpq5 libpq-dev libcairo2-dev build-essential unattended-upgrades cmake ccache \
               openmpi-bin linux-headers-5.4.0-117 linux-headers-5.4.0-117-generic linux-headers-generic libopenmpi-dev unixodbc-dev \
               sysstat ssh tmux supervisor && \
    apt-get install -y less vim && \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure && \
    # Initialize the default environment that Spark and notebooks will use
    virtualenv -p python3.8 --system-site-packages /databricks/python3 --no-download --no-setuptools --wheel 0.38.4 \
        && /databricks/python3/bin/pip install --no-cache-dir --upgrade pip \
        && /databricks/python3/bin/pip install \
            databricks-cli \
            ipython \
            ipykernel==6.12.1 \
            matplotlib==3.4.3 \
            numpy==1.20.1 \
            pandas==1.2.4 \
            pyarrow==4.0.0 \
            psycopg2==2.8.5 \
        && /databricks/python3/bin/pip install --force-reinstall \
            virtualenv \
        && /databricks/python3/bin/pip cache purge && \
    apt-get -y purge --autoremove software-properties-common cuda-cudart-dev-${CUDA_PKG_VERSION} cuda-cupti-dev-${CUDA_PKG_VERSION} \
               cuda-driver-dev-${CUDA_PKG_VERSION} cuda-nvcc-${CUDA_PKG_VERSION} cuda-thrust-${CUDA_PKG_VERSION} \
               python3.8-dev libpq-dev libcairo2-dev build-essential unattended-upgrades cmake ccache openmpi-bin \
               linux-headers-5.4.0-117 linux-headers-5.4.0-117-generic linux-headers-generic libopenmpi-dev unixodbc-dev \
               virtualenv python3-virtualenv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /databricks/jars && \
    mkdir -p /mnt/driver-daemon && \
    #############
    # Disable NVIDIA repos to prevent accidental upgrades.
    #############
    ln -s /databricks/jars /mnt/driver-daemon/jars && \
    cd /etc/apt/sources.list.d && \
    mv cuda.list cuda.list.disabled && \
    # Create user "ubuntu"
    useradd --create-home --shell /bin/bash --groups sudo ubuntu

#############
# Set all env variables
#############
ENV PYSPARK_PYTHON=/databricks/python3/bin/python3
ENV LANG=C.UTF-8
ENV USER=ubuntu
ENV PATH=/usr/local/nvidia/bin:/databricks/python3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

FROM base as with-plugin

#############
# Spark RAPIDS configuration
#############
ARG DRIVER_CONF_FILE=00-custom-spark-driver-defaults.conf
ARG JAR_FILE=rapids-4-spark_2.12-23.02.0.jar
ARG JAR_URL=https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/23.02.0/${JAR_FILE}
ARG INIT_SCRIPT=init.sh
COPY ${DRIVER_CONF_FILE} /databricks/driver/conf/00-custom-spark-driver-defaults.conf

WORKDIR /databricks/jars
ADD $JAR_URL /databricks/jars/${JAR_FILE}

ADD $INIT_SCRIPT /opt/spark-rapids/init.sh
RUN chmod 755 /opt/spark-rapids/init.sh

WORKDIR /databricks

# libganglia1 in ubuntu 20.04 actually is missing the modpython.so library
# needed for the GPU metrics plugin 
# this is actually a known packaging bug in Ubuntu
# See https://bugs.launchpad.net/ubuntu/+source/ganglia/+bug/1894045
# Therefore we need to download the package from Ubuntu 18.04 (which includes 
# the missing library)
FROM ubuntu:18.04 as download-modpython

RUN cd /tmp && \
  apt-get -y update && \
  apt-get -y download libganglia1 && \
  ls -al

#############
# Setup Ganglia
#############
FROM with-plugin as with-ganglia

ARG GANGLIA_WEBROOT=/usr/share/ganglia-webfrontend

WORKDIR /databricks
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -q -y --force-yes --fix-missing --ignore-missing \
        ganglia-monitor \
        ganglia-webfrontend \
        ganglia-monitor-python \
        libpython2.7 \
        python3-pip \
        wget \
        rsync \
        cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Upgrade Ganglia to 3.7.2 to patch XSS bug, see CJ-15250
# Upgrade Ganglia to 3.7.4 and use private forked repo to patch several security bugs, see CJ-20114
# SC-17279: We run gmetad as user ganglia, so change the owner from nobody to ganglia for the rrd directory
RUN cd /tmp \
  && export GANGLIA_WEB=ganglia-web-3.7.4-db-4 \
  && wget https://s3-us-west-2.amazonaws.com/databricks-build-files/$GANGLIA_WEB.tar.gz \
  && tar xvzf $GANGLIA_WEB.tar.gz \
  && cd $GANGLIA_WEB \
  && make install \
  && chown ganglia:ganglia /var/lib/ganglia/rrds
# Install Phantom.JS
RUN cd /tmp \
  && export PHANTOM_JS="phantomjs-2.1.1-linux-x86_64" \
  && wget https://s3-us-west-2.amazonaws.com/databricks-build-files/$PHANTOM_JS.tar.bz2 \
  && tar xvjf $PHANTOM_JS.tar.bz2 \
  && mv $PHANTOM_JS /usr/local/share \
  && ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin
# Install ganglia modpython from Ubuntu 18.04
COPY --from=download-modpython /tmp/libganglia1_*.deb /tmp
RUN cd /tmp \
  && mkdir -p /tmp/libganglia1 \
  && dpkg-deb -xv libganglia1_*.deb /tmp/libganglia1 \
  && cp /tmp/libganglia1/usr/lib/ganglia/modpython.so /usr/lib/ganglia/ \
  && rm -rf /tmp/libganglia1
# Apache2 config. The `sites-enabled` config files are loaded into the container
# later.
RUN rm /etc/apache2/sites-enabled/* && a2enmod proxy && a2enmod proxy_http
RUN mkdir -p /etc/monit/conf.d
RUN echo '\
check process ganglia-monitor with pidfile /var/run/ganglia-monitor.pid\n\
      start program = "/usr/sbin/service ganglia-monitor start"\n\
      stop program = "/usr/sbin/service ganglia-monitor stop"\n\
      if memory usage > 500 MB for 3 cycles then restart\n\
' > /etc/monit/conf.d/ganglia-monitor-not-active 
RUN echo '\
check process gmetad with pidfile /var/run/gmetad.pid\n\
      start program = "/usr/sbin/service gmetad start"\n\
      stop program = "/usr/sbin/service gmetad stop"\n\
      if memory usage > 500 MB for 3 cycles then restart\n\
\n\
check process apache2 with pidfile /var/run/apache2/apache2.pid\n\
      start program = "/usr/sbin/service apache2 start"\n\
      stop program = "/usr/sbin/service apache2 stop"\n\
      if memory usage > 500 MB for 3 cycles then restart\n\
' > /etc/monit/conf.d/gmetad-not-active
RUN echo '\
check process spark-slave with pidfile /tmp/spark-root-org.apache.spark.deploy.worker.Worker-1.pid\n\
      start program = "/databricks/spark/scripts/restart-workers"\n\
      stop program = "/databricks/spark/scripts/kill_worker.sh"\n\
' > /etc/monit/conf.d/spark-slave-not-active
# add Ganglia configuration file indicating the DocumentRoot - Databricks checks this to enable Ganglia upon cluster startup
RUN mkdir -p /etc/apache2/sites-enabled
ADD ganglia/ganglia.conf /etc/apache2/sites-enabled
RUN chmod 775 /etc/apache2/sites-enabled/ganglia.conf
ADD ganglia/gconf/*.conf /etc/ganglia/
RUN mkdir -p /databricks/spark/scripts/ganglia/
RUN mkdir -p /databricks/spark/scripts/
RUN mkdir -p $GANGLIA_WEBROOT/graph.d
ADD ganglia/start_spark_slave.sh /databricks/spark/scripts/start_spark_slave.sh

# add local monit shell script in the right location
RUN mkdir -p /etc/init.d
ADD scripts/monit /etc/init.d
RUN chmod 775 /etc/init.d/monit

# For GPU monitoring in Ganglia, you need the modules available here:
# https://github.com/ganglia/gmond_python_modules/tree/master/gpu/nvidia/python_modules
ADD ganglia/gconf/conf.d/* /etc/ganglia/conf.d/
ADD ganglia/python_modules/* /usr/lib/ganglia/python_modules
RUN /usr/bin/pip install --upgrade  -t /usr/lib/ganglia/python_modules/ nvidia-ml-py

# Copy the files needed for GPU monitoring in Ganglia

#############
# Set up webterminal ssh
#############
FROM with-ganglia as with-webterminal

RUN wget https://github.com/tsl0922/ttyd/releases/download/1.6.3/ttyd.x86_64 && \
        mkdir -p /databricks/driver/logs && \
        mkdir -p /databricks/spark/scripts/ttyd/ && \
        mkdir -p /etc/monit/conf.d/ && \
        mv ttyd.x86_64 /databricks/spark/scripts/ttyd/ttyd && \
        export TTYD_BIN_FILE=/databricks/spark/scripts/ttyd/ttyd

ENV TTYD_DIR=/databricks/spark/scripts/ttyd
ENV TTYD_BIN_FILE=$TTYD_DIR/ttyd
   
COPY webterminal/setup_ttyd_daemon.sh $TTYD_DIR/setup_ttyd_daemon.sh
COPY webterminal/stop_ttyd_daemon.sh $TTYD_DIR/stop_ttyd_daemon.sh
COPY webterminal/start_ttyd_daemon.sh $TTYD_DIR/start_ttyd_daemon.sh
COPY webterminal/webTerminalBashrc $TTYD_DIR/webTerminalBashrc
RUN echo '\
check process ttyd with pidfile /var/run/ttyd-daemon.pid\n\
      start program = "/databricks/spark/scripts/ttyd/start_ttyd_daemon.sh"\n\
      stop program = "/databricks/spark/scripts/ttyd/stop_ttyd_daemon.sh"' >  /etc/monit/conf.d/ttyd-daemon-not-active

FROM with-webterminal as with-alluxio
#############
# Setup Alluxio
#############
RUN apt-get update && apt-get install -q -y git maven
ARG ALLUXIO_VERSION=2.9.0
ARG ALLUXIO_HOME="/opt/alluxio-${ALLUXIO_VERSION}"
ARG ALLUXIO_TAR_FILE="alluxio-${ALLUXIO_VERSION}-bin.tar.gz"
ADD Alluxio-2.9.0-without-CVE /tmp/Alluxio-2.9.0-without-CVE
# clone 2.9.0 source, fix CVE issues, compile, then install to /opt/alluxio-x.x.x
RUN /tmp/Alluxio-2.9.0-without-CVE/build-from-src-and-fix-CVE.sh
RUN ln -s ${ALLUXIO_HOME} /opt/alluxio
RUN cp ${ALLUXIO_HOME}/client/alluxio-${ALLUXIO_VERSION}-client.jar /databricks/jars/

#############
# Setup Prometheus
#############
ARG PROMETHEUS_VERSION=2.37.6
ARG PROMETHEUS_TAR_FILE=prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
ARG PROMETHEUS_DOWNLOAD_URL=https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_TAR_FILE}
RUN wget -O /tmp/${PROMETHEUS_TAR_FILE} ${PROMETHEUS_DOWNLOAD_URL} \
    && tar zxf /tmp/${PROMETHEUS_TAR_FILE} -C /opt/ \
    && rm -f /tmp/${PROMETHEUS_TAR_FILE}

#############
# Allow ubuntu user to sudo without password
#############
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu \
    && chmod 555 /etc/sudoers.d/ubuntu
