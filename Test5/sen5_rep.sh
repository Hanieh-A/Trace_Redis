#!/bin/bash


PID=$(pidof redis-server)
echo "Redis PID: $PID"


sudo perf record -p $PID -e cache-misses:P -g -- sleep 30 &
PERF_PID=$!

sleep 2


redis-benchmark -t get -n 300000 -r 100000 -d 8192

wait $PERF_PID

sudo perf report --stdio | grep "redis-check-rdb" | grep "\[\.\]"
