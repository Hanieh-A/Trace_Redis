# sequential vs random
# stat
sudo perf stat -p $(pidof redis-server) \
-e cycles:u,\
instructions:u,\
cache-references:u,\
cache-misses:u,\
L1-dcache-loads:u,\
L1-dcache-load-misses:u,\
LLC-loads:u,\
LLC-load-misses:u

# record
sudo perf record -o ./test1/sequential.data -p $(pidof redis-server) \
-e cycles:u,\
instructions:u,\
cache-references:u,\
cache-misses:u,\
L1-dcache-loads:u,\
L1-dcache-load-misses:u,\
LLC-loads:u,\
LLC-load-misses:u





# working set size
sudo perf stat -p $(pidof redis-server) \
-e cycles:u,instructions:u,\
cycle_activity.stalls_l1d_miss:u,\
cycle_activity.stalls_l2_miss:u,\
cycle_activity.stalls_l3_miss:u,\
cycle_activity.stalls_mem_any:u,\
cache-references:u,cache-misses:u,\
L1-dcache-loads:u,L1-dcache-load-misses:u,\
l2_rqsts.miss:u,\
LLC-loads:u,LLC-load-misses:u sleep 30

# working set size in system-wide mode
sudo perf stat -a --topdown -- sleep 30

# record
sudo perf record -p $(pidof redis-server) -g -e cache-misses


# working set size 2
perf stat -e \
cycles,instructions,\
cache-references,cache-misses,\
L1-dcache-loads,L1-dcache-load-misses,\
LLC-loads,LLC-load-misses \
redis-benchmark \
GET key:__rand_int__ \
-r 1000 \
-c 1 \
-n 5000000

# modify
sudo perf stat -p $(pidof redis-server) \
-e cycles:u,\
instructions:u,\
cache-references:u,\
cache-misses:u,\
L1-dcache-loads:u,\
L1-dcache-load-misses:u,\
LLC-loads:u,\
LLC-load-misses:u,\
mem_fragmentation_ratio:u,\
page-faults:u

# multi-thread
sudo perf stat -p $(pidof redis-server) \
-e cycles:u,\
instructions:u,\
cache-references:u,\
cache-misses:u,\
L1-dcache-loads:u,\
L1-dcache-load-misses:u,\
LLC-loads:u,\
LLC-load-misses:u