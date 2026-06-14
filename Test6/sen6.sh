#!/bin/bash

N=300000
R=100000

PERF_EVENTS="cycles:u,instructions:u,cache-references:u,cache-misses:u,stalled-cycles-frontend:u,stalled-cycles-backend:u,branch-instructions:u,branch-misses:u"

VALUE_SIZE=128

echo "=============================="
echo "STRING STRUCTURE"
echo "=============================="

redis-cli flushall

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -t set -n $N -r $R -d $VALUE_SIZE

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -t get -n $N -r $R -d $VALUE_SIZE


echo "=============================="
echo "HASH STRUCTURE"
echo "=============================="

redis-cli flushall

# populate hash
for i in $(seq 1 100000); do
    redis-cli HSET myhash field$i value$i > /dev/null
done

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -n $N -r $R hget myhash field:__rand_int__

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -n $N -r $R hset myhash field:__rand_int__ value:__rand_int__


echo "=============================="
echo "SORTED SET STRUCTURE"
echo "=============================="

redis-cli flushall

# populate sorted set
for i in $(seq 1 50000); do
    redis-cli ZADD myzset $i member:$i > /dev/null
done

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -n $N zrange myzset 0 99

sudo perf stat -e $PERF_EVENTS \
redis-benchmark -n $N -r $R zadd myzset __rand_int__ member:__rand_int__
