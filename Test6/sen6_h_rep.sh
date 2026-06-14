#!/bin/bash


for i in $(seq 1 10000); do
    redis-cli HSET myhash field$i value$i > /dev/null
done


PID=$(pidof redis-server)
echo "Redis PID: $PID"


sudo perf record -e cache-misses:P -p $PID -g -- sleep 20 &
PERF_PID=$!

sleep 2

redis-benchmark -n 300000 -r 100000 hget myhash field:__rand_int__


wait $PERF_PID
sudo perf report --stdio
