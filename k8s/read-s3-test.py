# Import SparkSession
from pyspark.sql import SparkSession
import time

# Create SparkSession 
spark = SparkSession.builder.appName("s3-read-test").getOrCreate()
data_path = "s3a://tpcds-share-emr/sf10-parquet/useDecimal=true,useDate=true,filterNull=false/call_center"
column_name = "cc_call_center_id"
spark.read.parquet(data_path).select(column_name).show()
# sleep 300 seconds to allow user to check the Spark UI
time.sleep(300)
spark.stop()
