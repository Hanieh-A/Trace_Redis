# Scenario 4: Multi-Threaded Access

## Objective

This experiment evaluates the impact of parallel execution on Redis performance. Although Redis is fundamentally single-threaded, multiple client threads were introduced to simulate concurrent workloads and analyze how cache behavior and execution time scale with increased parallelism.

## Experiment 1: Increasing Number of Reader Threads

The system was tested with 1, 4, and 8 concurrent threads issuing read operations.

### Results

| Metric           | 1 Thread | 4 Threads | 8 Threads |
| ---------------- | -------: | --------: | --------: |
| Cycles           |    1.43B |     5.98B |    12.95B |
| Instructions     |  926.59M |     3.69B |     7.40B |
| IPC              |     0.65 |      0.62 |      0.57 |
| Cache References |    5.79M |    24.69M |   105.82M |
| Cache Misses     |    3.12M |    10.87M |    17.81M |
| Cache Miss Rate  |   53.88% |    44.02% |    16.83% |
| L1 Loads         |  256.83M |     1.02B |     2.05B |
| L1 Load Misses   |   23.63M |   112.13M |   258.65M |
| L1 Miss Rate     |    9.20% |    10.96% |    12.63% |
| LLC Loads        |    1.12M |     4.72M |    15.63M |
| LLC Load Misses  |  812.14K |     3.02M |     5.23M |
| LLC Miss Rate    |   72.28% |    63.96% |    33.44% |
| Execution Time   |  14.69 s |   34.30 s |   71.32 s |

## Experiment 2: Mixed Read-Write Workload

To better simulate realistic workloads, a mixed configuration was tested where some threads perform reads and others perform writes.

Two configurations were evaluated:

* 2 writer / 2 reader threads
* 4 writer / 4 reader threads

### Results

| Metric           | 2W / 2R | 4W / 4R |
| ---------------- | ------: | ------: |
| Cycles           |   7.18B |  15.49B |
| Instructions     |   4.91B |   9.62B |
| IPC              |    0.68 |    0.62 |
| Cache References |  32.78M | 150.80M |
| Cache Misses     |  13.31M |  25.28M |
| Cache Miss Rate  |  40.59% |  16.76% |
| L1 Loads         |   1.33B |   2.60B |
| L1 Load Misses   | 127.64M | 282.08M |
| L1 Miss Rate     |   9.61% |  10.84% |
| LLC Loads        |   6.38M |  22.86M |
| LLC Load Misses  |   3.71M |   7.23M |
| LLC Miss Rate    |  58.22% |  31.61% |
| Execution Time   | 40.15 s | 81.82 s |

## Analysis

### Scaling Behavior

As the number of threads increases, total execution time increases significantly. This indicates that Redis becomes a performance bottleneck under high concurrency due to its single-threaded core execution model. Even though multiple client threads issue requests in parallel, all operations are ultimately serialized within the Redis server.

This serialization leads to contention and increased scheduling overhead, which explains the sharp rise in execution time from 14.7 seconds (1 thread) to 71.3 seconds (8 threads).

### Cache Behavior

Interestingly, cache miss rates decrease as the number of threads increases. This trend is visible in both read-only and mixed workloads.

This behavior can be explained by better utilization of the overall CPU cache hierarchy:

* With more threads, the aggregate working set is distributed across multiple execution streams.
* The combined cache capacity across cores becomes more effectively utilized.
* Frequently accessed data may remain resident in shared cache levels (especially LLC), reducing the probability of repeated expensive memory accesses.

### Read-Write Concurrency

In mixed workloads, increasing both writer and reader threads leads to higher absolute cache traffic but lower relative miss rates in LLC compared to smaller configurations.

However, IPC decreases slightly as thread count increases, indicating that instruction throughput is limited by memory system pressure and synchronization overhead.

### Conclusion

Overall, increasing concurrency leads to:

* Higher total execution time due to Redis serialization bottlenecks.
* Lower cache miss rates due to improved aggregate cache utilization across threads and cores.
* Increased memory traffic and coordination overhead in mixed workloads.

These results highlight a key trade-off in single-threaded systems: while external parallelism increases request pressure, internal execution remains a limiting factor, and performance scaling is dominated by synchronization and memory hierarchy behavior rather than pure computation.
