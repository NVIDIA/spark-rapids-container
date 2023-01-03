#
# Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.
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
#

# A Dockerfile for building a container dedicated to run inside k8s cluster.
ARG CUDA_VER=11.5.0
ARG UBUNTU_VER=18.04
FROM nvidia/cuda:${CUDA_VER}-runtime-ubuntu${UBUNTU_VER}

# All build args with default values
ARG spark_uid=185
ARG SPARK_VER=3.2.2
ARG HADOOP_VER=3.2
ARG RAPIDS_VER=22.10.0
ARG hadoop_aws_ver=3.3.1
ARG aws_java_sdk_bundle_ver=1.11.655
ARG gcs_connector_ver=2.2.2


ENV DEBIAN_FRONTEND=noninteractive
# https://forums.developer.nvidia.com/t/notice-cuda-linux-repository-key-rotation/212771
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub

# Install java dependencies
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jdk openjdk-8-jre gpg gpg-agent wget
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-amd64
ENV PATH $PATH:/usr/lib/jvm/java-1.8.0-openjdk-amd64/jre/bin:/usr/lib/jvm/java-1.8.0-openjdk-amd64/bin

# Install Spark with desired versions
WORKDIR /opt

RUN set -ex && \
    wget -O spark-KEYS "https://downloads.apache.org/spark/KEYS" && \
    gpg --import spark-KEYS && \
    wget https://archive.apache.org/dist/spark/spark-$SPARK_VER/spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz.asc && \
    wget -O spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=spark/spark-$SPARK_VER/spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz" && \
    gpg --verify spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz.asc spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz && \
    tar zxfv spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz && \
    ln -s spark-$SPARK_VER-bin-hadoop$HADOOP_VER spark
ENV PATH=/opt/spark/bin:$PATH
ENV PYTHONPATH /opt/spark/python/lib/pyspark.zip:/opt/spark/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH

# Install rapids plugin jar
WORKDIR /opt/spark/jars
RUN set -ex && \
    wget -O rapids-4-spark-KEYS https://keys.openpgp.org/vks/v1/by-fingerprint/7A8A39909B9B202410C2A26F1D9E1285654392EF && \
    gpg --import rapids-4-spark-KEYS && \
    wget https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/$RAPIDS_VER/rapids-4-spark_2.12-$RAPIDS_VER-cuda11.jar.asc && \
    wget https://repo1.maven.org/maven2/com/nvidia/rapids-4-spark_2.12/$RAPIDS_VER/rapids-4-spark_2.12-$RAPIDS_VER-cuda11.jar && \
    gpg --verify rapids-4-spark_2.12-$RAPIDS_VER-cuda11.jar.asc rapids-4-spark_2.12-$RAPIDS_VER-cuda11.jar

# Add necessary jars to support AWS s3 storage access
RUN set -ex && \
    wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/$hadoop_aws_ver/hadoop-aws-$hadoop_aws_ver.jar && \
    wget https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/$aws_java_sdk_bundle_ver/aws-java-sdk-bundle-$aws_java_sdk_bundle_ver.jar
# Add necessary jars to support GCS storage access
RUN set -ex && \
    wget https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop3-$gcs_connector_ver/gcs-connector-hadoop3-$gcs_connector_ver-shaded.jar
# TODO: Add necessary jars to support Azure storage access

# TODO: Investigate running both pip and pip3 via virtualenvs
RUN apt-get update && \
    apt install -y python python-pip && \
    apt install -y python3 python3-pip && \
    # We remove ensurepip since it adds no functionality since pip is
    # installed on the image and it just takes up 1.6MB on the image
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    # You may install with python3 packages by using pip3.6
    # Removed the .cache to save space
    rm -r /root/.cache && rm -rf /var/cache/apt/*

ENV SPARK_HOME /opt/spark

RUN mkdir -p /opt/spark/work-dir
WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +rx /usr/bin/tini

RUN rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd

ENTRYPOINT [ "/opt/spark/kubernetes/dockerfiles/spark/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
