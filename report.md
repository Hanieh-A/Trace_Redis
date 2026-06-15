# Scenario 5: Impact of Value Size on Redis Cache Performance

## Overview

The objective of this experiment is to investigate how increasing Redis value size affects cache behavior, memory hierarchy utilization, and overall throughput.

The benchmark was executed using four different value sizes:

* 16 Bytes
* 128 Bytes
* 1024 Bytes
* 8192 Bytes

For each value size, three workloads were analyzed:

1. SET
2. GET
3. MODIFY (overwrite existing values)

Performance counters were collected using Linux `perf` and Redis Benchmark.

---

# Experimental Environment

## Database

* Redis Server

## Benchmark Tool

* redis-benchmark

## Profiling Tool

* Linux perf

---

# Performance Events

The following hardware events were collected during the experiments:

```bash
cycles
instructions
cache-references
cache-misses
branch-instructions
branch-misses

L1-dcache-loads
L1-dcache-load-misses

LLC-loads
LLC-load-misses

LLC-stores
LLC-store-misses
```

---


---

# Results

## SET

| Value Size | Requests/sec | IPC  | Cache References | Cache Misses | Miss Rate (%) | Branch Miss (%) | L1-dcache-load-misses | LLC load misses |
| ---------- | ------------ | ---- | ---------------- | ------------ | ------------- | --------------- | --------------------- | --------------- |
| 16         | 160256.41    | 1.59 | 67,662,956       | 1,336,449    | 1.975         | 0.59            | 8.40                  | 19.69           |
| 128        | 165837.48    | 1.54 | 68,045,984       | 1,499,609    | 2.204         | 0.79            | 9.34                  | 19.44           |
| 1024       | 163220.89    | 1.48 | 73,380,745       | 2,429,976    | 3.311         | 0.99            | 9.37                  | 10.39           |
| 8192       | 192802.06    | 1.22 | 145,394,874      | 5,361,834    | 3.688         | 1.18            | 12.77                 | 1.44            |

---

## GET

| Value Size | Requests/sec | IPC  | Cache References | Cache Misses | Miss Rate (%) | Branch Miss (%) | L1-dcache-load-misses | LLC load misses |
| ---------- | ------------ | ---- | ---------------- | ------------ | ------------- | --------------- | --------------------- | --------------- | 
| 16         | 265721.88    | 1.58 | 66,840,722       | 1,093,907    | 1.637         | 0.68            | 8.71                  | 14.79           |
| 128        | 264084.50    | 1.55 | 67,986,807       | 1,387,303    | 2.041         | 0.71            | 8.86                  | 14.71           |
| 1024       | 259965.33    | 1.58 | 71,562,886       | 1,755,058    | 2.452         | 0.62            | 11.55                 | 15.50           |
| 8192       | 184388.45    | 1.36 | 146,686,081      | 7,838,980    | 4.420         | 1.03            | 39.33                 | 4.15

---

## MODIFY

| Value Size | Requests/sec | IPC  | Cache References | Cache Misses | Miss Rate (%) | Branch Miss (%) | 
| ---------- | ------------ | ---- | ---------------- | ------------ | ------------- | --------------- | 
| 16         | 252312.86    | 1.13 | 1,283,583        | 125,136      | 9.749         | 1.32            |
| 128        | 254237.30    | 1.13 | 1,675,053        | 124,235      | 7.417         | 1.26            |
| 1024       | 243309.00    | 1.11 | 1,597,972        | 169,434      | 7.068         | 1.61            |
| 8192       | 217864.92    | 1.06 | 6,153,857        | 169,925      | 2.761         | 1.69            |

---

# Analysis

For SET operations, increasing value size generally increases cache references and cache misses.

This behavior is expected because Redis must:

* Receive larger payloads
* Allocate more memory
* Copy more data
* Manage larger objects

As a consequence:

1. More accesses are issued to the cache hierarchy.
2. Larger values are less likely to fit completely inside cache levels.
3. Cache miss rate increases.
4. CPU spends more time waiting on memory accesses.

The reduction in IPC for larger values confirms that memory latency becomes a larger bottleneck.

---

For GET operations, a similar trend is observed.

Retrieving larger values requires:

* Reading more bytes from memory
* Traversing larger memory regions
* Increased pressure on cache hierarchy

The 8192-byte workload exhibits the highest miss rate and the lowest throughput among all GET workloads.

---

Branch miss rates remain relatively stable across all experiments.

This indicates that branch prediction is not a major contributor to performance degradation in this workload.

Instead, memory hierarchy behavior dominates execution time.

---

# Perf Record Analysis

---

# Hot Functions

| Function          | Description                |
| ----------------- | -------------------------- |
| dictSdsKeyCompare | Key comparison             |
| dictFind          | Hash table lookup          |
| lookupKey         | Redis key retrieval        |
| addReplyBulkLen   | Client response generation |
| getCommand        | GET command handler        |

The majority of cache misses originate from hash table traversal and key comparison operations.

---

# Perf Annotate

The following assembly instructions generated the largest number of cache misses:

| Instruction | Reason                                  |
| ----------- | --------------------------------------- |
| movzbl      | Loading bytes from Redis key strings    |
| movslq      | Hash table lookup and pointer traversal |

These instructions correspond to memory accesses performed while traversing Redis dictionaries and comparing keys.

---

# Conclusion

The experiment demonstrates that cache behavior significantly influences Redis performance.

As value size increases:

* Cache references increase.
* Cache misses increase.
* IPC decreases.
* Throughput eventually drops.

The dominant source of cache misses is hash table traversal and key comparison rather than branch prediction.

Therefore, memory hierarchy efficiency plays a critical role in Redis performance under large-value workloads.





# Scenario 6: Comparison of Redis Data Structures

## Overview

The goal of this experiment is to compare the cache behavior and execution characteristics of different Redis data structures.

The following Redis data structures were evaluated:

* String
* Hash
* Sorted Set

For each structure, both insertion and retrieval operations were benchmarked while collecting hardware performance counters using Linux `perf`.

---

# Experimental Environment

## Database

* Redis Server

## Benchmark Tool

* redis-benchmark

## Profiling Tool

* Linux perf

---

# Performance Events

---

# Time Complexity

| Operation | Complexity   |
| --------- | ------------ |
| SET       | O(1)         |
| GET       | O(1)         |
| HSET      | O(1)         |
| HGET      | O(1)         |
| ZADD      | O(log N)     |
| ZRANGE    | O(log N + M) |

Theoretical complexity suggests that String and Hash operations should perform similarly, while Sorted Set operations require additional work because of Skip List traversal and ordering maintenance.

---

# Results

## Overall Performance

| Data Structure | Operation | Requests/sec | Miss Rate (%) | Cycles        | Instructions  | IPC  | 
| -------------- | --------- | ------------ | ------------- | ------------- | ------------- | ---- |
| String         | SET       | 167317.34    | 1.741         | 4,321,171,767 | 6,995,604,017 | 1.62 | 
| String         | GET       | 164293.55    | 1.528         | 4,368,631,367 | 7,022,059,148 | 1.61 |
| Hash           | HSET      | 166204.98    | 1.974         | 4,316,263,091 | 6,919,531,623 | 1.60 |
| Hash           | HGET      | 166759.31    | 1.917         | 4,322,682,392 | 6,953,123,922 | 1.61 |
| Sorted Set     | ZADD      | 165289.25    | 3.586         | 4,309,347,278 | 7,050,256,558 | 1.64 | 
| Sorted Set     | ZRANGE    | 148001.98    | 1.475         | 4,891,682,459 | 8,618,029,760 | 1.76 |

---

# Data Structure Internals

## String

String is the simplest Redis data structure.

Internally it stores:

```text
Key -> Value
```

Only a single lookup is required.

Advantages:

* Excellent spatial locality
* Minimal pointer traversal
* Low cache miss rate
* Fastest memory access pattern

---

## Hash

Hash introduces an additional lookup layer:

```text
Key -> Field -> Value
```

Redis must:

1. Locate the hash object.
2. Locate the requested field.
3. Return the associated value.

This additional level of indirection increases cache pressure.

Hash tables may also require:

* Collision resolution
* Linked list traversal
* Rehashing operations

which can increase cache misses.

---

## Sorted Set

Sorted Set is the most complex structure evaluated.

Internally it combines:

```text
Hash Table
+
Skip List
```

When inserting a new element Redis must:

1. Update the hash table.
2. Locate insertion position in skip list.
3. Update multiple forward pointers.

Consequently:

* More memory accesses occur.
* More pointer chasing occurs.
* Cache locality decreases.

---

# Analysis

## String vs Hash

String and Hash exhibit very similar throughput and IPC values.

However, Hash consistently shows a higher miss rate.

This is expected because Hash requires:

* Additional hash table lookups
* Pointer dereferencing
* Traversal of collision chains

String accesses are more direct and cache friendly.

---

## Sorted Set Behavior

Sorted Set shows the highest cache miss rate during insertion.

The reason is that ZADD modifies two structures simultaneously:

* Hash Table
* Skip List

Insertion requires locating the correct position and updating multiple pointers.

As a result:

* Cache references increase.
* Cache misses increase.
* Memory locality decreases.

---

## Why ZRANGE Has Lower Throughput

ZRANGE exhibits the lowest requests per second.

Although its cache miss rate is relatively low, it executes significantly more instructions.

This happens because:

* Multiple skip list nodes must be traversed.
* More comparisons are performed.
* More data must be prepared for the response.

Consequently execution time increases despite efficient cache utilization.


---

# Hash Hot Functions

| Function             | Reason                    |
| -------------------- | ------------------------- |
| dictSdsKeyCompare    | Field comparison          |
| dictFind             | Hash bucket lookup        |
| prepareClientToWrite | Client response buffering |
| aeProcessEvents      | Event loop processing     |

The majority of cache misses originate from hash table traversal and field comparison.

HGET requires two lookup stages:

1. Locate the hash object.
2. Locate the target field.

This explains why dictionary-related functions dominate cache miss statistics.

---

# Observations from ZRANGE

A significant portion of execution time is spent in:

* TCP communication
* Socket writes
* Kernel networking stack
* Data transmission to the benchmark client

This indicates that ZRANGE performance becomes partially network-bound rather than purely cache-bound.

Therefore kernel networking functions may dominate the profile instead of Redis internal algorithms.


+   68.66%     0.66%  redis-server  [kernel.kallsyms]   [k] entry_SYSCALL_64_af
+   67.72%     0.48%  redis-server  [kernel.kallsyms]   [k] do_syscall_64      
+   64.72%     0.40%  redis-server  [kernel.kallsyms]   [k] x64_sys_call       
+   47.13%     0.59%  redis-server  libpthread-2.31.so  [.] __libc_write       
+   43.25%     0.29%  redis-server  [kernel.kallsyms]   [k] __x64_sys_write    
+   42.93%     0.25%  redis-server  [kernel.kallsyms]   [k] ksys_write         
+   42.01%     0.38%  redis-server  [kernel.kallsyms]   [k] vfs_write         
+   41.38%     0.25%  redis-server  [kernel.kallsyms]   [k] new_sync_write     
+   41.14%     0.54%  redis-server  [kernel.kallsyms]   [k] sock_write_iter    
+   40.61%     0.11%  redis-server  [kernel.kallsyms]   [k] __sock_sendmsg     
+   40.29%     0.19%  redis-server  [kernel.kallsyms]   [k] inet_sendmsg       
+   40.09%     0.28%  redis-server  [kernel.kallsyms]   [k] tcp_sendmsg        
+   38.97%     1.46%  redis-server  [kernel.kallsyms]   [k] tcp_sendmsg_locked 
+   32.00%     0.33%  redis-server  [kernel.kallsyms]   [k] tcp_push           
+   31.70%     0.14%  redis-server  [kernel.kallsyms]   [k] __tcp_push_pending_
+   31.47%     0.69%  redis-server  [kernel.kallsyms]   [k] tcp_write_xmit     

---

# Conclusion

The experiment demonstrates that data structure design has a direct impact on cache behavior.

Performance ranking from a cache locality perspective:

1. String
2. Hash
3. Sorted Set

Main findings:

* String provides the best cache locality.
* Hash introduces additional pointer chasing.
* Sorted Set incurs the highest insertion overhead.
* ZADD produces the largest cache miss rate.
* ZRANGE executes the largest number of instructions.
* Memory hierarchy behavior plays a significant role in Redis performance.

Overall, cache-friendly data structures achieve higher throughput and lower latency due to improved spatial and temporal locality.
