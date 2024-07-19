#!/bin/bash

# Run from the directory where the configuration files are located

# Backup and update core-site.xml
echo "Backing up core-site.xml..."
cp core-site.xml core-site.xml.backup
echo "Updating core-site.xml..."

## <value>hdfs://namenode:9000</value>가 있다면 <value>hdfs://hadoop-master:9000/</value>로 변경
sed -i 's|<value>hdfs://hadoop-master:9000/</value>|<value>hdfs://namenode:9000</value>|' core-site.xml
## hadoop.tmp.dir가 있다면 /hadoop/tmp로 바꾸고, 없다면 해당 항목으로 생성
sed -i '/fs.defaultFS/a \    <property>\n      <name>hadoop.tmp.dir</name>\n      <value>/hadoop/tmp</value>\n    </property>' core-site.xml
## io.file.buffer.size의 내용이 원래 존재한다면  131072로 바꾸고, 없다면 해당 항목으로 생성
sed -i '/hadoop.tmp.dir/a \    <property>\n      <name>io.file.buffer.size</name>\n      <value>131072</value>\n    </property>' core-site.xml

# Backup and update hdfs-site.xml
echo "Backing up hdfs-site.xml..."
cp hdfs-site.xml hdfs-site.xml.backup
echo "Updating hdfs-site.xml..."
# dfs.replication내용이 원래 존재한다면 내용을 2로 바꾸고, 없다면 바꾸려는 내용으로 항목 생성
sed -i 's|<value>3</value>|<value>2</value>|' hdfs-site.xml
# dfs.blocksize에 대한 내용이 원래 존재한다면 내용을 134217728로 바꾸고, 없다면 바꾸려는 내용으로 항목 생성
sed -i 's|file:///usr/local/hadoop/data/namenode|/hadoop/dfs/name|' hdfs-site.xml
# dfs.namenode.name.dir에 대한 내용이 원래 존재한다면 내용을  /hadoop/dfs/name에 대한 내용으로 바꾸고, 없으면 바꾸려는 내용으로 항목 생성

# Backup and update mapred-site.xml
echo "Backing up mapred-site.xml..."
cp mapred-site.xml mapred-site.xml.backup
echo "Updating mapred-site.xml..."
# mapreduce.framework.name의 내용이 원래 존재한다면 yarn으로 바꾸고, 없다면 해당 내용을 생성
# mapreduce.jobhistory.address에 대한 내용이 원래 존재한다면 namenode:10020에 대한 내용으로 변경하고, 없다면 바꾸려는 내용으로 생성
# mapreduce.task.io.sort.mb에 대한 내용이 원래 존재한다면, 256에 대한 내용으로 변경하고, 없다면 바꾸려는 내용으로 항목 생성
sed -i 's|<value>yarn</value>|<value>yarn</value>|' mapred-site.xml
sed -i '/mapreduce.framework.name/a \    <property>\n      <name>mapreduce.jobhistory.address</name>\n      <value>namenode:10020</value>\n    </property>' mapred-site.xml
sed -i '/mapreduce.jobhistory.address/a \    <property>\n      <name>mapreduce.task.io.sort.mb</name>\n      <value>256</value>\n    </property>' mapred-site.xml

# Backup and update yarn-site.xml
# yarn.resourcemanager.address에 대한 내용이 존재한다면 namenode:8032에 대한 내용으로 바꾸고, 없다면 바꾸려는 내용으로 항목 생성
# yarn.nodemanager.resource.memory-mb에 대한 내용이 존재한다면 그 내용을 8192에 대한 내용으로 바꾸고, 없다면 바꾸려는 내용으로 항목 생성 
# yarn.scheduler.minimum-allocation-mb에 대한 내용이 존재한다면 그 내용을 1024에 대한 내용으로 바꾸고, 없다면 바꾸려는 내용으로 항목을 생성
echo "Backing up yarn-site.xml..."
cp yarn-site.xml yarn-site.xml.backup
echo "Updating mapred-site.xml..."
sed -i 's|<value>hadoop-master</value>|<value>namenode</value>|' yarn-site.xml
sed -i 's|<value>4096</value>|<value>8192</value>|' yarn-site.xml
sed -i '/yarn.nodemanager.resource.memory-mb/a \    <property>\n      <name>yarn.scheduler.minimum-allocation-mb</name>\n      <value>1024</value>\n    </property>' yarn-site.xml

# Restart Hadoop services
# 명령은 아래와 같아야한다고 함. 혹시 오류가 있다면 수정
echo "Restarting Hadoop DFS..."
hdfs -daemon dfs stop
hdfs -daemon dfs start
echo "Restarting YARN..."
hdfs -daemon yarn stop
hdfs -daemon yarn start

echo "Configuration changes applied and services restarted."
