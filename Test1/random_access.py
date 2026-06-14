import redis
import random

r = redis.Redis(host="localhost", port=6379)

N = 100000
REPEAT = 10

keys = list(range(N))
random.shuffle(keys)

for _ in range(REPEAT):
    for k in keys:              # <-- استفاده از لیست تصادفی شده
        r.get(f"key:{k}")