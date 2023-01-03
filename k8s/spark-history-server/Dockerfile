ARG SPARK_VER=3.2.2
FROM apache/spark:v${SPARK_VER}

# Add necessary jars to support AWS s3 storage access
ADD https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar $SPARK_HOME/jars
ADD https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.11.655/aws-java-sdk-bundle-1.11.655.jar $SPARK_HOME/jars
ADD https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop3-2.2.2/gcs-connector-hadoop3-2.2.2-shaded.jar $SPARK_HOME/jars
# Note: due to https://github.com/helm/charts/blob/master/stable/spark-history-server/templates/deployment.yaml#L42
# which is using "command" instead of "arg", the "entrypoint" will not be used.
# So assign root user to avoid the following error when starting SHS:
# javax.security.auth.login.LoginException: java.lang.NullPointerException: invalid null input: name
USER root
