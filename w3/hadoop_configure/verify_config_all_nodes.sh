#!/bin/bash

# Docker Compose를 사용하여 실행 중인 모든 컨테이너의 이름을 얻고, 각 컨테이너에 대해 명령을 실행
for container in $(docker-compose ps -q); do

    hostname=$(docker exec $container hostname | tr -d '\r\n')
    echo "##########################"
    echo "########### $hostname"
    echo "##########################"
    
    docker cp verify_config.sh $container:/usr/local/hadoop/etc/hadoop/verify_config.sh

    # 복사된 스크립트의 실행 권한 변경
    docker exec -it $container sudo chmod +x /usr/local/hadoop/etc/hadoop/verify_config.sh

    # 스크립트 실행
    docker exec -it $container /usr/local/hadoop/etc/hadoop/verify_config.sh
done