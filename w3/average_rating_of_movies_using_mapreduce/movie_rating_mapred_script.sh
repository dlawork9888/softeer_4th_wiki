#!/bin/bash


##### 컨테이너 내부로 tweets, mapper, reducer 복사

# tweets 컨테이너 내부로 복사
docker cp ratings.csv hadoop-master:/temp

# mapper, reducer 컨테이너 내부로 복사
docker cp movie_rating_mapper.py hadoop-master:/temp/movie_rating_mapper.py 
docker cp movie_rating_reducer.py hadoop-master:/temp/movie_rating_reducer.py

### 해당 파일들을 실행 가능한 파일로 변경 (chmod +x)
### !!!!!! #!/usr/bin/env python3 필수 !!!!!!!!
docker exec -it hadoop-master sudo chmod +x /temp/movie_rating_mapper.py /temp/movie_rating_reducer.py

##### HDFS에 tweets 옮기기

# hdfs에 tweets directory 생성
docker exec -it hadoop-master hdfs dfs -mkdir -p /movie_rating_dir

# 해당 디렉토리로 tweets 옮기기
docker exec -it hadoop-master hdfs dfs -put /temp/ratings.csv /movie_rating_dir


##### MapReduce 작업 실행
# movie_rating_output 디렉토리는 생성됨
docker exec -it hadoop-master hadoop jar /usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
  -input /movie_rating_dir/ratings.csv \
  -output /movie_rating_output \
  -mapper movie_rating_mapper.py \
  -reducer movie_rating_reducer.py \
  -file /temp/movie_rating_mapper.py \
  -file /temp/movie_rating_reducer.py


##### 호스트 머신으로 결과 가져오기

# 컨테이너 로컬 파일 시스템의 /temp의 소유권을 hadoopuser로 변경
docker exec -it hadoop-master sudo chown hadoopuser:hadoopuser temp

# HDFS의 movie_rating_output 디렉토리를 컨테이너의 로컬 디렉토리로 가져옴
docker exec -it hadoop-master hdfs dfs -get /movie_rating_output /temp

# 결과를 호스트 머신(Mac)의 현재 폴더로 가져옴
docker cp hadoop-master:/temp/movie_rating_output .