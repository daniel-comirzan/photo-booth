#!/usr/bin/env bash

command=$1

case $command in
  "build")
    docker build -f Dockerfile -t photo:latest .
    ;;
  "run")
    env | grep AWS > .env
    [ `docker images | grep photo | grep latest | wc -l` == 0 ] && bash runDocker.sh build
    docker run -v$HOME/.aws:/root/.aws:ro \
           -v$PWD:/app \
            --env-file .env \
            --rm -it \
            photo:latest
    ;;
  "*")
    echo "Unknow command"
    exit 0
    ;;
esac