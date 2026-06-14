# Scenario 3: Data Modification

## Objective

This experiment investigates the cache behavior of Redis during update operations. Unlike read-only workloads, modification operations require both reading existing data and writing updated values back to memory, potentially generating additional cache traffic and memory allocations.

Three different modification scenarios were evaluated:

1. Updating 100,000 existing values while keeping their size unchanged.
2. Updating 100,000 existing values while also changing their size.
3. Repeating the experiment with only 100 keys to observe the impact of a small working set.

## Results

### Effect of Value Resizing

The first comparison evaluates the impact of changing object sizes during updates.

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

Compared to fixed-size updates:

* Cache references increased by approximately 42%.
* Cache misses increased by approximately 63%.
* LLC miss rate increased from 59.8% to 68.8%.
* Page faults more than doubled.

These results suggest that memory reallocations introduce additional memory accesses and reduce cache locality. The allocator may need to allocate new memory regions, copy data, and update metadata structures, resulting in increased cache pressure.

The reduction in IPC from 0.97 to 0.93 also indicates that the processor spends more time waiting for memory operations.

### Effect of Working Set Size

To evaluate the impact of dataset size, the variable-size update experiment was repeated using only 100 keys. To maintain a sufficient profiling duration, the update loop was executed 20,000 times.

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

### Analysis

Reducing the working set size dramatically improves cache efficiency.

The most significant improvement occurs at the last-level cache:

* LLC miss rate decreases from **68.84%** to **5.46%**.
* LLC misses drop from approximately **6.8 million** to fewer than **200 thousand**.

In contrast, the L1 miss rate remains relatively stable. This suggests that the primary benefit comes from improved utilization of higher cache levels rather than changes in L1 behavior.

Because the smaller dataset fits comfortably within the cache hierarchy, data evicted from L1 can often be served from L2 or L3 without requiring expensive accesses to main memory.

This improvement is reflected in IPC, which increases from **0.93** to **1.15**, indicating more efficient processor utilization and fewer memory-related stalls.

Overall, the results demonstrate that working set size has a major impact on LLC performance and overall memory efficiency during Redis update operations.
