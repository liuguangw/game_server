#!/bin/sh

echo " stop game Server ......"

docker-compose stop -t 180 game_server
docker-compose stop db_server