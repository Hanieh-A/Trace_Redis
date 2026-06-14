#!/bin/bash

SIZES=(16 128 1024 8192)
N=300000
R=100000

PERF_EVENTS="cycles:u,instructions:u,cache-references:u,cache-misses:u,stalled-cycles-frontend:u,stalled-cycles-backend:u,branch-instructions:u,branch-misses:u"

for SIZE in "${SIZES[@]}"; do
    echo "=============================="
    echo "Scenario 1 - SET size=$SIZE"
    echo "=============================="

    redis-cli flushall

    sudo perf stat -e $PERF_EVENTS \
    redis-benchmark -t set -n $N -r $R -d $SIZE

    echo ""
    echo "Scenario 1 - GET size=$SIZE"

    sudo perf stat -e $PERF_EVENTS \
    redis-benchmark -t get -n $N -r $R -d $SIZE

    echo ""
    echo "Scenario 1 - MODIFY (SET overwrite) size=$SIZE"

    sudo perf stat -e $PERF_EVENTS \
    redis-benchmark -t set -n $N -r $R -d $SIZE
done
