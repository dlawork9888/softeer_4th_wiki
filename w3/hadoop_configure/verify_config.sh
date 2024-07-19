#!/bin/bash

# Run from the directory where the configuration files are located

# Check Hadoop configuration settings
function check_config {
    local key=$1
    local expected=$2
    local value=$(hdfs getconf -confKey $key)

    if [[ $value == $expected ]]; then
        echo "PASS: $key -> $value"
    else
        echo "FAIL: $key -> $value (expected $expected)"
    fi
}

echo "Verifying Hadoop configuration..."

# Verify core-site.xml settings
check_config "fs.defaultFS" "hdfs://namenode:9000"
check_config "hadoop.tmp.dir" "/hadoop/tmp"
check_config "io.file.buffer.size" "131072"

# Verify hdfs-site.xml settings
check_config "dfs.replication" "2"
check_config "dfs.namenode.name.dir" "/hadoop/dfs/name"

# Verify mapred-site.xml settings
check_config "mapreduce.framework.name" "yarn"
check_config "mapreduce.jobhistory.address" "namenode:10020"
check_config "mapreduce.task.io.sort.mb" "256"

# Verify yarn-site.xml settings
check_config "yarn.resourcemanager.address" "namenode:8032"
check_config "yarn.nodemanager.resource.memory-mb" "8192"
check_config "yarn.scheduler.minimum-allocation-mb" "1024"

echo "Verification completed."
