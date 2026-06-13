import redis
import threading
import random
import time

r = redis.Redis(host="localhost", port=6379)

TOTAL_KEYS = 100_000
OPS = 200_000


# initialize database
for i in range(TOTAL_KEYS):
    r.set(f"key:{i}", 0)


def writer():
    r = redis.Redis(host="localhost", port=6379)

    for _ in range(200_000):
        k = random.randint(0, TOTAL_KEYS - 1)
        # overwrite existing value
        r.set(f"key:{k}", random.randint(1, 1000))

def reader():
    r = redis.Redis(host="localhost", port=6379)

    for _ in range(200_000):
        k = random.randint(0, TOTAL_KEYS - 1)
        r.get(f"key:{k}")



threads = []

# 2 writer threads
for _ in range(4):
    t = threading.Thread(target=writer)
    threads.append(t)

# 2 reader threads
for _ in range(4):
    t = threading.Thread(target=reader)
    threads.append(t)

start = time.time()

for t in threads:
    t.start()

for t in threads:
    t.join()