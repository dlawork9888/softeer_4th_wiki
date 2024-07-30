#!/bin/bash


# NYC_TLC_data 폴더안의 모든 파일을 컨테이너 로컬 파일 시스템(/temp)으로 이동
docker cp NYC_TLC_data/ spark-master:/temp

# hdfs에 NYC_TLC_data 디렉토리 생성
docker exec -it spark-master hdfs dfs -mkdir /NYC_TLC_data

# 폴더 확인
docker exec -it spark-master hdfs dfs -ls /

# 로컬파일시스템의 /temp에 있는 모든 파일을 hdfs로 업로드 
docker exec -it spark-master hdfs dfs -put /temp /NYC_TLC_data
# => temp폴더 전체가 올라가서 NYC_TLC_data/temp/개별파일들 <- 요래됐음;;;

# hdfs 파일 업로드 확인
hdfs dfs -ls /NYC_TLC_data/temp