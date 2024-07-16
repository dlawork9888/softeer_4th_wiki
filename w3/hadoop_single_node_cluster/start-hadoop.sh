#!/bin/bash

# Start SSH service as root
sudo service ssh start

# Start Hadoop services as hadoopuser

hdfs namenode -format
start-dfs.sh
start-yarn.sh

# Keep the container running
tail -f /dev/null
