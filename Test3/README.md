# Scenario 3: Data Modification

## Objective

This experiment investigates the cache behavior of Redis during update operations. Unlike read-only workloads, modification operations require both reading existing data and writing updated values back to memory, potentially generating additional cache traffic and memory allocations.

Three different modification scenarios were evaluated:

1. Updating 100,000 existing values while keeping their size unchanged.
2. Updating 100,000 existing values while also changing their size.
3. Repeating the experiment with only 100 keys to observe the impact of a small working set.

## Experiment 1: Updating Values Without Changing Their Size

A dataset containing 100,000 keys was created. Each value was then modified by replacing the character `A` with `B` while keeping the overall object size unchanged.

### Results

| Metric           | Fixed-Size Update |
| ---------------- | ----------------: |
| Cycles           |            14.96B |
| Instructions     |            14.52B |
| IPC              |              0.97 |
| Cache References |            98.68M |
| Cache Misses     |            64.88M |
| Cache Miss Rate  |            65.75% |
| L1 Loads         |             3.91B |
| L1 Load Misses   |           352.90M |
| L1 Miss Rate     |             9.04% |
| LLC Loads        |             9.35M |
| LLC Load Misses  |             5.59M |
| LLC Miss Rate    |            59.79% |
| Page Faults      |            66,691 |
| Execution Time   |           77.03 s |

## Experiment 2: Updating Values and Changing Their Size

The same dataset of 100,000 keys was used again. This time, values were modified such that alternating entries became either larger or smaller than their original size.

Changing the object size may require memory reallocation and movement of data within the Redis allocator, introducing additional memory overhead.

### Results

| Metric           | Fixed-Size Update | Variable-Size Update |
| ---------------- | ----------------: | -------------------: |
| Cycles           |            14.96B |               17.33B |
| Instructions     |            14.52B |               16.20B |
| IPC              |              0.97 |                 0.93 |
| Cache References |            98.68M |              139.95M |
| Cache Misses     |            64.88M |              105.57M |
| Cache Miss Rate  |            65.75% |               75.43% |
| L1 Loads         |             3.91B |                4.35B |
| L1 Load Misses   |           352.90M |              423.10M |
| L1 Miss Rate     |             9.04% |                9.73% |
| LLC Loads        |             9.35M |                9.85M |
| LLC Load Misses  |             5.59M |                6.78M |
| LLC Miss Rate    |            59.79% |               68.84% |
| Page Faults      |            66,691 |              147,663 |
| Execution Time   |           77.03 s |              75.60 s |

### Analysis

Changing the size of values significantly increases memory activity.

Compared to the fixed-size update workload:

* Cache references increased by approximately 42%.
* Cache misses increased by approximately 63%.
* LLC miss rate increased from 59.8% to 68.8%.
* Page faults more than doubled.

These results suggest that memory reallocations introduce additional memory accesses and reduce cache locality. The allocator may need to allocate new memory regions, copy existing data, and update internal metadata structures, all of which contribute to increased cache pressure.

The decrease in IPC from 0.97 to 0.93 further indicates that the processor spends more time waiting for memory operations to complete.

## Experiment 3: Small Working Set (100 Keys)

The experiment was repeated using only 100 keys.

To ensure sufficient runtime for profiling, the update operation was executed repeatedly for 20,000 iterations.

### Results

| Metric           | Variable-Size Update (100,000 Keys) | Variable-Size Update (100 Keys) |
| ---------------- | ----------------------------------: | ------------------------------: |
| Cycles           |                              17.33B |                          11.24B |
| Instructions     |                              16.20B |                          12.88B |
| IPC              |                                0.93 |                            1.15 |
| Cache References |                             139.95M |                          47.12M |
| Cache Misses     |                             105.57M |                           3.02M |
| Cache Miss Rate  |                              75.43% |                           6.42% |
| L1 Loads         |                               4.35B |                           3.55B |
| L1 Load Misses   |                             423.10M |                         372.76M |
| L1 Miss Rate     |                               9.73% |                          10.49% |
| LLC Loads        |                               9.85M |                           3.44M |
| LLC Load Misses  |                               6.78M |                         187.86K |
| LLC Miss Rate    |                              68.84% |                           5.46% |
| Execution Time   |                             75.60 s |                         67.14 s |

## Analysis

Reducing the working set from 100,000 keys to only 100 keys dramatically improves cache behavior.

The most notable improvement is observed in the last-level cache:

* LLC miss rate decreases from **68.84%** to **5.46%**.
* LLC misses drop from approximately **6.8 million** to only **188 thousand**.

Interestingly, the L1 miss rate remains relatively unchanged. This suggests that most of the performance improvement comes from better utilization of higher cache levels rather than from changes in L1 cache behavior.

Because the entire dataset easily fits within the cache hierarchy, data that is evicted from L1 can still be retrieved from L2 or L3 without requiring expensive accesses to main memory.

The improvement is also reflected in processor efficiency, with IPC increasing from **0.93** to **1.15**, indicating that the CPU spends less time stalled on memory accesses and more time executing useful instructions.

Overall, these results demonstrate that working set size has a much stronger effect on LLC performance than on L1 cache performance. When the dataset fits comfortably within the cache hierarchy, Redis can serve update operations with substantially fewer memory-access penalties.
