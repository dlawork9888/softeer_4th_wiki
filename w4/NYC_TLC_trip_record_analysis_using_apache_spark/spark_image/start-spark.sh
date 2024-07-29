#!/bin/bash

## spark_image/start-spark.sh

# master -> start-master.sh / worker
if [ "$SPARK_MASTER" = "true" ]; then
    if [ ! -d "/opt/hadoop/data/namenode/current" ]; then
        hdfs namenode -format -force -nonInteractive
        sudo chmod 777 /opt/hadoop/data/namenode/
    fi
    hdfs --daemon start namenode
    hdfs --daemon start secondarynamenode
    $SPARK_HOME/sbin/start-master.sh
else
    hdfs --daemon start datanode    
    $SPARK_HOME/sbin/start-worker.sh spark://spark-master:7077
fi

# Keep the container running
tail -f /dev/null
