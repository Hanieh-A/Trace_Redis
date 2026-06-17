# Scenario 1: Sequential Access vs. Random Access

## Objective

The goal of this experiment is to investigate the impact of memory locality on cache performance by comparing sequential and random access patterns in Redis.

## Experimental Setup

First, all existing Redis data was cleared using:

```bash
redis-cli FLUSHALL
```

A Python script was then used to populate Redis with an initial dataset containing **100,000 keys**.

Two different access patterns were evaluated:

1. **Sequential Access** – keys were read in ascending order.
2. **Random Access** – keys were accessed in a random order.

Performance metrics were collected using `perf stat`.

## Results

| Metric                       | Sequential Access | Random Access |
| ---------------------------- | ----------------: | ------------: |
| Cycles                       |     6,267,567,834 | 5,967,516,001 |
| Instructions                 |     4,792,114,005 | 4,623,269,858 |
| Instructions per Cycle (IPC) |              0.76 |          0.77 |
| Cache References             |        18,986,427 |    13,506,453 |
| Cache Misses                 |         9,215,999 |     7,042,194 |
| Cache Miss Rate              |            48.54% |        52.14% |
| L1 Data Cache Loads          |     1,328,017,556 | 1,281,132,014 |
| L1 Data Cache Load Misses    |       112,684,980 |   111,867,145 |
| L1 Data Cache Miss Rate      |             8.49% |         8.73% |
| Execution Time               |           33.48 s |       31.58 s |

## Analysis

The results show that the two access patterns exhibit very similar cache behavior. Although random access produces a slightly higher cache miss rate, the difference is relatively small.

Even when larger datasets were tested, the observed behavior remained largely unchanged. A likely explanation is Redis's internal data organization. Since keys are stored in hash tables, both sequential and random key lookups ultimately involve hash-based access patterns. As a result, the memory access locality expected from sequential traversal is not fully reflected at the cache level.

Therefore, in this experiment, the access order of keys had only a limited impact on overall cache performance.
