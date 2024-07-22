#!/bin/bash

# 함수: 설정 검사
check_config() {
    key=$1
    expected_value=$2
    command=($3 "${@:4}")

    actual_value=$("${command[@]}")
    if [ "$actual_value" == "$expected_value" ]; then
        echo "PASS: [${command[*]}] -> $expected_value" 
    else
        echo "FAIL: [${command[*]}] -> $actual_value (expected $expected_value)"
    fi
}

# Hadoop 및 YARN 설정 검사 => 에러 해결중 ...
check_config "fs.defaultFS" "hdfs://hadoop-master:9000" "hdfs" "getconf" "-confKey" "fs.defaultFS"
check_config "hadoop.tmp.dir" "file:///usr/local/hadoop/tmp" "hdfs" "getconf" "-confKey" "hadoop.tmp.dir"
check_config "io.file.buffer.size" "131072" "hdfs" "getconf" "-confKey" "io.file.buffer.size"
check_config "dfs.replication" "2" "hdfs" "getconf" "-confKey" "dfs.replication"
check_config "dfs.blocksize" "134217728" "hdfs" "getconf" "-confKey" "dfs.blocksize"
check_config "dfs.namenode.name.dir" "file:///usr/local/hadoop/dfs/name" "hdfs" "getconf" "-confKey" "dfs.namenode.name.dir"
check_config "mapreduce.framework.name" "yarn" "hadoop" "getconf" "-confKey" "mapreduce.framework.name"
check_config "mapreduce.jobhistory.address" "hadoop-master:10020" "hadoop" "getconf" "-confKey" "mapreduce.jobhistory.address"
check_config "mapreduce.task.io.sort.mb" "256" "hadoop" "getconf" "-confKey" "mapreduce.task.io.sort.mb"
check_config "yarn.resourcemanager.address" "hadoop-master:8032" "yarn" "getconf" "-confKey" "yarn.resourcemanager.address"
check_config "yarn.nodemanager.resource.memory-mb" "8192" "yarn" "getconf" "-confKey" "yarn.nodemanager.resource.memory-mb"
check_config "yarn.scheduler.minimum-allocation-mb" "1024" "yarn" "getconf" "-confKey" "yarn.scheduler.minimum-allocation-mb"


hostname=$(docker exec $container hostname | tr -d '\r\n')

if [ "$hostname" == "hadoop-master" ]; then
    # 추가적인 Hadoop 및 YARN 작업
    echo "Creating a test file on HDFS..."
    hdfs dfs -touchz /testfile.txt
    replication_factor=$(hdfs fsck /testfile.txt -files -blocks -locations | grep 'replication' | awk '{print $2}')
    if [ "$replication_factor" == "2 (configured)" ]; then
        echo "PASS: replication factor 2"
    else
        echo "FAIL: replication factor $replication_factor (expected 2)"
    fi

    # 간단한 MapReduce 작업 실행
    echo "Running a simple MapReduce job..."
    mapred jar /usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar example.WordCount input output
    result=$(hadoop fs -cat output/part-r-00000)
    echo "MapReduce output: $result"

    # YARN ResourceManager 질의
    echo "Querying YARN ResourceManager for total available memory..."
    available_memory=$(yarn node -status <nodeID> | grep 'Total Memory' | awk '{print $3}')
    echo "Total available memory in YARN: $available_memory MB"
fi