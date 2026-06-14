# Scenario 2: Working Set Size

## Objective

The purpose of this experiment is to investigate how the size of the working set affects cache performance in Redis. By gradually increasing the dataset size, we can observe how cache behavior changes as the working set exceeds the capacity of different cache levels.

## Cache Hierarchy

The cache sizes of the test machine were obtained using:

```bash
lscpu | grep cache
```

Output:

| Cache Level          | Size    |
| -------------------- | ------- |
| L1 Data Cache        | 192 KiB |
| L1 Instruction Cache | 128 KiB |
| L2 Cache             | 5 MiB   |
| L3 Cache             | 12 MiB  |

Since the processor contains four cores, the effective cache capacity available per core for the private cache levels (L1 and L2) is approximately one quarter of the reported values.

## Estimating Memory Usage per Key

First, the memory consumption of an empty Redis instance was measured:

```bash
redis-cli INFO memory | grep used_memory:
```

Output:

```text
used_memory:858528
```

After inserting 1,000 keys, memory usage became:

```text
used_memory:945920
```

Therefore:

```text
(945920 - 858528) / 1000 = 87.392 bytes
```

Each Redis entry occupies approximately **87 bytes** of memory.

Based on this estimate, the following dataset sizes were selected:

| Number of Keys | Approximate Dataset Size | Expected Cache Level |
| -------------- | ------------------------ | -------------------- |
| 100            | 8.7 KB                   | Fits within L1       |
| 1,000          | 87 KB                    | Fits within L2       |
| 10,000         | 874 KB                   | Fits within L3       |
| 100,000        | 8.7 MB                   | Exceeds L3           |

## Measuring Stall Cycles

When using `perf stat` in per-thread mode (`-p`), several Top-Down Analysis events, including stall-cycle-related metrics, are not available.

Since Redis was the only CPU-intensive process running during the experiment, Top-Down metrics were collected separately using system-wide mode (`-a`). The remaining cache-related events were measured in per-thread mode.

## Results

### Cache Performance

| Metric           | 100 Keys (L1) | 1,000 Keys (L2) | 10,000 Keys (L3) | 100,000 Keys (>L3) |
| ---------------- | ------------: | --------------: | ---------------: | -----------------: |
| Cycles           |         3.95B |           4.23B |            4.67B |              5.47B |
| Instructions     |         3.83B |           4.41B |            4.46B |              4.40B |
| IPC              |          0.97 |            1.04 |             0.95 |               0.80 |
| Cache References |        17.28M |           9.66M |           12.06M |             16.77M |
| Cache Misses     |         3.26M |           2.10M |            4.58M |              8.97M |
| Cache Miss Rate  |        18.87% |          21.79% |           37.97% |             53.45% |
| L1 Loads         |         1.11B |           1.27B |            1.27B |              1.25B |
| L1 Load Misses   |        96.84M |         115.70M |          109.86M |            112.50M |
| L1 Miss Rate     |         8.71% |           9.08% |            8.63% |              9.01% |
| L2 Misses        |        18.70M |          10.34M |           13.11M |             17.81M |
| LLC Loads        |         2.17M |           1.18M |            2.10M |              3.00M |
| LLC Load Misses  |          333K |            220K |             922K |              2.07M |
| LLC Miss Rate    |        15.36% |          18.67% |           44.01% |             68.89% |
| Execution Time   |       30.00 s |         30.00 s |          30.00 s |            30.00 s |

### Top-Down Analysis

| Metric          | 100 Keys (L1) | 1,000 Keys (L2) | 10,000 Keys (L3) | 100,000 Keys (>L3) |
| --------------- | ------------: | --------------: | ---------------: | -----------------: |
| Retiring        |         27.3% |           27.5% |            27.1% |              27.1% |
| Bad Speculation |          8.6% |            9.1% |             8.7% |               8.8% |
| Frontend Bound  |         49.7% |           47.3% |            48.5% |              47.1% |
| Backend Bound   |         14.3% |           16.1% |            15.7% |              17.0% |

## Analysis

As the working set grows beyond the capacity of higher cache levels, cache efficiency gradually decreases.

The overall cache miss rate increases from **18.9%** when the dataset fits within L1 cache to **53.5%** when the dataset exceeds the L3 cache capacity. A similar trend can be observed in LLC miss rates, which increase dramatically from **15.4%** to **68.9%**.

Instruction throughput also decreases. IPC drops from approximately **1.0** to **0.8**, indicating that the processor spends more cycles waiting for memory accesses rather than executing useful instructions.

The Top-Down analysis shows that the workload remains heavily **frontend-bound**, with nearly half of the execution time spent waiting for instruction delivery. However, the percentage of **backend-bound** cycles increases as the dataset grows, suggesting additional delays caused by memory accesses and cache misses.

Overall, the results clearly demonstrate that larger working sets reduce cache effectiveness and increase memory-access latency.

## Effect of CPU Core Affinity

To evaluate the impact of CPU migration, the experiment with 100,000 keys was repeated while forcing Redis to run on a single CPU core.

### Comparison

| Metric          | Multiple Cores | Single Core |
| --------------- | -------------: | ----------: |
| Cycles          |          5.47B |       5.64B |
| Instructions    |          4.40B |       4.60B |
| IPC             |           0.80 |        0.82 |
| Cache Miss Rate |         53.45% |      64.69% |
| L1 Load Misses  |        112.50M |     113.05M |
| L1 Miss Rate    |          9.01% |       8.66% |
| LLC Load Misses |          2.07M |       2.10M |
| LLC Miss Rate   |         68.89% |      77.51% |
| Execution Time  |        30.00 s |     30.00 s |

## Analysis

The L1 cache miss rate is slightly lower when Redis is pinned to a single CPU core. When a process migrates between cores, the private L1 cache of the new core must be populated again, which can introduce additional cache misses.

In contrast, the LLC (L3 cache) is shared among all cores. Therefore, CPU migration has a smaller impact on the availability of data in the last-level cache.

These results suggest that cache locality can benefit from CPU affinity, particularly for the private cache levels, although the overall impact on execution time remains relatively small in this workload.


## Instruction-Level Cache Miss Analysis Using `perf record`

While `perf stat` provides aggregate cache statistics, it does not reveal which parts of the Redis code are responsible for the observed cache misses. To identify the most expensive memory-access patterns, instruction-level profiling was performed using `perf record`.

For the dataset containing 100 keys, cache misses were recorded using:

```bash
sudo perf record -p <pid> -g -e cache-misses
```

The collected samples were stored in `perf.data` and analyzed using:

```bash
perf report
```

The report shows the percentage of cache-miss samples attributed to different functions and instructions.

### 1. `lookupKey`

The first function examined was `lookupKey`, which implements the main key lookup routine in Redis.

A heavily sampled instruction sequence was:

```asm
mov     %eax,%edx
movzbl  (%r12),%eax
or      %edx,%eax
mov     %eax,(%r12)
```

Approximately 85% of the cache-miss samples in this code path were associated with this sequence.

The highlighted instructions perform the following operations:

1. Load a value from the memory address stored in `r12`.
2. Combine it with the value in `edx`.
3. Write the result back to the same memory location.

It is important to note that the percentage shown next to the `or` instruction does not imply that the `or` operation itself caused the cache miss. The `or` instruction does not access memory. Instead, the cache miss occurred during the preceding memory load, and the sampled event happened to be attributed to the next instruction when execution resumed.

### 2. `dictFind`

The second important function was `dictFind`, which is responsible for locating a key inside Redis's hash table implementation.

One of the most frequently sampled instruction sequences was:

```asm
mov     0x10(%r12),%r12
test    %r12,%r12
je      ...
```

This code performs linked-list traversal by following pointers between hash table entries.

The presence of this code confirms that Redis stores keys using a hash-table-based data structure. Every `GET` request eventually reaches this lookup routine.

Pointer chasing is particularly expensive for cache performance because the processor cannot easily predict where the next node will reside in memory. Since linked-list nodes may be scattered throughout the heap, each pointer dereference can potentially trigger a cache miss.

### 3. `__memset_avx2_erms`

Another frequently sampled function was `__memset_avx2_erms`.

This routine is part of the standard C library and is invoked whenever a memory region must be initialized or filled with a specific value. Since it operates on large memory regions, it naturally generates a significant amount of memory traffic and may contribute to cache misses.

### 4. `dictSdsKeyCompare`

The `dictSdsKeyCompare` function is responsible for comparing keys stored within a hash-table bucket.

When a command such as:

```text
GET key123
```

is executed, Redis first computes the hash value of `key123` and uses it to locate the corresponding bucket. If multiple keys are stored in that bucket due to hash collisions, Redis invokes `dictSdsKeyCompare` to compare the candidate keys byte-by-byte until the correct key is found.

This comparison process may generate additional cache misses because the actual string contents are stored separately from the hash table entry and must be fetched through pointers.

## Memory Access Path During a Redis Lookup

The instruction-level analysis reveals the sequence of memory accesses involved in a typical Redis lookup:

1. **Hash Table Lookup**

   * Redis accesses the hash table and locates the bucket corresponding to the requested key.
   * If the bucket is not already cached, a cache miss may occur.

2. **Hash Bucket Traversal**

   * The bucket may contain multiple entries.
   * Redis traverses linked structures to inspect each candidate entry.
   * Since these entries are often distributed throughout the heap, pointer chasing can cause additional cache misses.

3. **Key Comparison**

   * Redis compares the requested key against the keys stored in the bucket.
   * The actual string data is accessed through pointers, introducing further memory accesses and potential cache misses.

4. **Value Retrieval**

   * After locating the correct key, Redis retrieves the associated value.
   * The value itself is typically referenced through another pointer rather than being stored directly inside the hash-table entry.
   * This final dereference may result in another cache miss.

Overall, the profiling results indicate that cache misses are primarily caused by pointer-heavy data structures and indirect memory accesses rather than by computational instructions. The hash-table lookup process itself is relatively efficient, but the required pointer dereferences and heap accesses introduce latency that becomes increasingly visible as the working set grows beyond cache capacity.
