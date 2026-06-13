import redis
import sys

r = redis.Redis(host="localhost", port=6379)

N = 1000

r.flushall()

for i in range(N):
    r.set(f"key:{i}", "value")

# print(f"{N} keys inserted")


TOTAL_GETS = 1_000_000

repeat = TOTAL_GETS // N

for _ in range(repeat):
    for i in range(N):
        r.get(f"key:{i}")