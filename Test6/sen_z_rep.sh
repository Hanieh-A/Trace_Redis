#!/bin/bash

for i in $(seq 1 50000); do
    redis-cli ZADD myzset $i member:$i > /dev/null
done


PID=$(pidof redis-server)
echo "Redis PID: $PID"


sudo perf record -p $PID -e cycles:P -g -- sleep 20 &
PERF_PID=$!

sleep 2


redis-benchmark -n 300000 zrange myzset 0 99


wait $PERF_PID
sudo perf report --stdio | grep "redis-check-rdb" | grep "\[\.\]"
