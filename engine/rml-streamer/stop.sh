#!/usr/bin/env bash

#echo "Killing timestamping script..."
#cat pid |xargs sudo kill 
#echo "Killed"

echo "Stoping streamer's docker containers..."
docker-compose down

#echo "Removing latency_log/ directories..."
#read -p "Are you sure? " -n 1 -r
#echo    # (optional) move to a new line
#
#if [[ ! $REPLY =~ ^[Yy]$ ]]
#then
#    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
#fi
#
#rm -rf latency_log

