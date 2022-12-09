#!/bin/bash
set -e

# clone, apply patches and compile
cd /tmp/Alluxio-2.9.0-without-CVE
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git clone https://github.com/Alluxio/alluxio.git
cd alluxio/
git checkout v2.9.0 -b v2.9.0-fix-cve
git am < /tmp/Alluxio-2.9.0-without-CVE/patches/0001-Fix-CVE-issues.patch
git am < /tmp/Alluxio-2.9.0-without-CVE/patches/0002-Fix-CVE-issues.patch
git am < /tmp/Alluxio-2.9.0-without-CVE/patches/0003-Fix-CVE-issues.patch
echo "Compiling Alluxio, this may take some time ..."
mvn clean install -q -Pufs-hadoop-3 -Dufs.hadoop.version=3.2.4 -Dmaven.javadoc.skip=true -Dmaven.test.skip=true -Dlicense.skip=true -Dcheckstyle.skip=true -Dfindbugs.skip=true -Dhadoop.version=3.2.4 -T 4
echo "Compile done"
# setup Alluxio program located in `/opt` path
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
cp ./alluxio/lib/alluxio-underfs-local-2.9.0.jar ./alluxio-2.9.0/lib
cp ./alluxio/lib/alluxio-underfs-s3a-2.9.0.jar ./alluxio-2.9.0/lib
cp -r ./libexec ./alluxio-2.9.0
cp ./alluxio/LICENSE ./alluxio-2.9.0/LICENSE
mkdir ./alluxio-2.9.0/webui
cp -r ./alluxio/webui/master ./alluxio-2.9.0/webui
cp -r ./alluxio/webui/worker ./alluxio-2.9.0/webui
mkdir ./alluxio-2.9.0/logs
mv alluxio-2.9.0 /opt
rm -rf /tmp/Alluxio-2.9.0-without-CVE
