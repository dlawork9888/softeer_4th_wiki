##### HADOOP
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    net-tools \ 
    vim \
    openssh-server \ 
    openssh-client \
    sudo \
    rsync

# ssh 폴더
RUN mkdir /var/run/sshd 

##### JAVA 설치 및 환경변수 설정
RUN apt-get install -y openjdk-11-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64
ENV PATH=${PATH}:${JAVA_HOME}/bin

# Python 설치
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip

# 나만의 작은 temp 디렉토리
RUN mkdir /temp

# 하둡 설치 파일 압축 해제
# /opt/hadoop
COPY hadoop-3.3.6.tar.gz /temp/
RUN tar -xzvf /temp/hadoop-3.3.6.tar.gz -C /opt/ && \
    mv /opt/hadoop-3.3.6 /opt/hadoop && \
    rm /temp/hadoop-3.3.6.tar.gz

# 하둡 설정 파일 COPY
# /opt/hadoop/etc/hadoop
COPY hadoop_config/* /opt/hadoop/etc/hadoop/

# 하둡 환경 변수 설정
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_INSTALL=/opt/hadoop
ENV HADOOP_MAPRED_HOME=/opt/hadoop
ENV HADOOP_COMMON_HOME=/opt/hadoop
ENV HADOOP_HDFS_HOME=/opt/hadoop
ENV YARN_HOME=/opt/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR=/opt/hadoop/lib/native
ENV PATH=$PATH:/opt/hadoop/sbin:/opt/hadoop/bin
# 자바 환경 변수도 넣어줌
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64' >> /opt/hadoop/etc/hadoop/hadoop-env.sh

# root 계정 설정, sparkuser 추가 및 sudo 권한 부여
RUN echo 'root:root' | chpasswd
RUN useradd -m -s /bin/bash sparkuser && \
    echo "sparkuser:sparkuser" | chpasswd && \
    adduser sparkuser sudo

# sparkuser -> 비밀번호 없이 sudo 명령을 실행할 수 있도록
RUN echo 'sparkuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH 설정
RUN mkdir /home/sparkuser/.ssh && \
    chmod 700 /home/sparkuser/.ssh && \
    ssh-keygen -t rsa -P '' -f /home/sparkuser/.ssh/id_rsa && \
    cat /home/sparkuser/.ssh/id_rsa.pub >> /home/sparkuser/.ssh/authorized_keys && \
    chmod 600 /home/sparkuser/.ssh/authorized_keys && \
    chown -R sparkuser:sparkuser /home/sparkuser/.ssh

# SSH 구성 변경: 루트 로그인 허용 및 패스워드 인증 활성화
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN echo "AllowUsers sparkuser" >> /etc/ssh/sshd_config

# 포트 노출
EXPOSE 22 9870 8088
# 하둡 디렉토리 및 파일의 소유권을 hadoopuser로 변경
RUN chown -R sparkuser:sparkuser /opt/hadoop


##### Spark 
# Spark -> 다운로드 시간은 사치
COPY spark-3.5.1-bin-hadoop3.tgz /temp/

# Spark 압축풀기
RUN tar -xvf /temp/spark-3.5.1-bin-hadoop3.tgz -C /opt/ && \
    mv /opt/spark-3.5.1-bin-hadoop3 /opt/spark && \
    rm -rf /temp  # 파일 삭제 후 디렉토리 제거

# Spark Home
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

##### 사용자 설정
# sparkuser 생성 및 환경 변수 적용
RUN usermod -aG sudo sparkuser && \
    echo 'export SPARK_HOME=/opt/spark' >> /home/sparkuser/.bashrc && \
    echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> /home/sparkuser/.bashrc && \
    mkdir -p /home/sparkuser && \
    chown -R sparkuser:sparkuser /home/sparkuser /opt/spark

##### 시작
# 시작 스크립트 복사
COPY --chown=sparkuser:sparkuser start-spark.sh /opt/spark/sbin/start-spark.sh
# 실행가능파일로 변경
RUN chmod +x /opt/spark/sbin/start-spark.sh

# 유저 설정
USER sparkuser

##### RUN
CMD ["/opt/spark/sbin/start-spark.sh"]
