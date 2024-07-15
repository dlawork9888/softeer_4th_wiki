# Base image
FROM ubuntu:20.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk wget curl net-tools vim

# Set environment variables
# 자바 경로 못잡길래 직접 찍어봄
# JAVA_HOME = /usr/lib/jvm/java-8-openjdk-arm64
# PATH 변수에 $JAVA_HOME/bin 추가
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV HADOOP_VERSION=3.4.0
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$JAVA_HOME/bin

# Download and extract Hadoop
RUN wget https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz -P /tmp && \
    tar -xvzf /tmp/hadoop-$HADOOP_VERSION.tar.gz -C /usr/local && \
    mv /usr/local/hadoop-$HADOOP_VERSION /usr/local/hadoop && \
    rm /tmp/hadoop-$HADOOP_VERSION.tar.gz

# Configure Hadoop
COPY config/* $HADOOP_HOME/etc/hadoop/

# Format namenode
RUN $HADOOP_HOME/bin/hdfs namenode -format

# Expose ports
EXPOSE 9870 8088

# Start Hadoop services
CMD ["sh", "-c", "$HADOOP_HOME/sbin/start-dfs.sh && $HADOOP_HOME/sbin/start-yarn.sh && tail -f /dev/null"]
