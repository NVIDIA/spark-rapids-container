#!/bin/bash
# Copyright (c) 2022, NVIDIA CORPORATION.
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

#############################################
# This script is used to compile, patch Alluxio code and install Alluxio to fix the Alluxio CVE issues.
# Waiting Alluxio to fix all the Alluxio CVE issues will be a long-term work.
# So we fix CVE issues by workaround method: build Alluxio ourselves, exclude and upgrade some 3PP jars.
#############################################

set -e

# clone Alluxio code, apply patches and compile
cd /tmp/Alluxio-2.9.0-without-CVE
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git clone https://github.com/Alluxio/alluxio.git
cd alluxio/
git checkout v2.9.0 -b v2.9.0-fix-cve
git am /tmp/Alluxio-2.9.0-without-CVE/patches/*
# update `libexec/alluxio-config.sh`, replace the client and server jar as the Alluxio building script does.
# For details, refer to:
# https://github.com/Alluxio/alluxio/blob/v2.9.0/dev/scripts/src/alluxio.org/build-distribution/cmd/generate-tarball.go#L274-L275
git am /tmp/Alluxio-2.9.0-without-CVE/update-assembly-jar-path.patch

echo "Compiling Alluxio, this may take some time ..."
mvn clean install -q -Pufs-hadoop-3 -Dufs.hadoop.version=3.2.4 -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Dlicense.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true -Dhadoop.version=3.2.4 -T 4
echo "Compile done"

# setup Alluxio program located in `/opt` path
# This section is copying only specific jars so we can avoid CVE issues in the unused jars
cd ../
mkdir alluxio-2.9.0
cp -r ./alluxio/bin ./alluxio-2.9.0
mkdir ./alluxio-2.9.0/assembly
cp ./alluxio/assembly/server/target/alluxio-assembly-server-2.9.0-jar-with-dependencies.jar ./alluxio-2.9.0/assembly/alluxio-server-2.9.0.jar
cp ./alluxio/assembly/client/target/alluxio-assembly-client-2.9.0-jar-with-dependencies.jar ./alluxio-2.9.0/assembly/alluxio-client-2.9.0.jar
mkdir ./alluxio-2.9.0/client
cp ./alluxio/client/alluxio-2.9.0-client.jar ./alluxio-2.9.0/client
cp -r ./alluxio/conf/ ./alluxio-2.9.0/conf
cp ./log4j2-master.properties ./log4j2-worker.properties ./alluxio-2.9.0/conf
mkdir ./alluxio-2.9.0/lib
# Skip coping other /lib/alluxio-underfs-xxx.jar except the underfs-local and underfs-s3a 2 jars
cp ./alluxio/lib/alluxio-underfs-local-2.9.0.jar ./alluxio-2.9.0/lib
cp ./alluxio/lib/alluxio-underfs-s3a-2.9.0.jar ./alluxio-2.9.0/lib
cp -r ./alluxio/libexec ./alluxio-2.9.0

cp ./alluxio/LICENSE ./alluxio-2.9.0/LICENSE
mkdir ./alluxio-2.9.0/webui
cp -r ./alluxio/webui/master ./alluxio-2.9.0/webui
cp -r ./alluxio/webui/worker ./alluxio-2.9.0/webui
mkdir ./alluxio-2.9.0/logs
mv alluxio-2.9.0 /opt
rm -rf /tmp/Alluxio-2.9.0-without-CVE
rm -rf ~/.m2
