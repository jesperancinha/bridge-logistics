#!/usr/bin/env bash

docker stop bl-bridge-server-container

docker rm bl-bridge-server-container

docker-compose down

docker stop docker-psql_postgres_1

cd docker-psql

docker-compose down

cd ..

./stopMacOs.sh
