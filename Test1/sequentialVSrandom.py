import redis
import random
import time

r = redis.Redis(host="localhost", port=6379)
N = 100000

# پر کردن دیتابیس
for i in range(N):
    r.set(f"key:{i}", f"value:{i}")

def flush_cache():
    """پاک کردن کش Redis"""
    r.flushall()  # کل دیتابیس رو پاک می‌کنه
    # دوباره پر کردن
    for i in range(N):
        r.set(f"key:{i}", f"value:{i}")

# تست ترتیبی با کش سرد
flush_cache()
start = time.time()
for i in range(N):
    r.get(f"key:{i}")
sequential_time = time.time() - start

# تست تصادفی با کش سرد
flush_cache()
keys = list(range(N))
random.shuffle(keys)
start = time.time()
for k in keys:
    r.get(f"key:{k}")
random_time = time.time() - start

print(f"Sequential (cold cache): {sequential_time:.2f}s")
print(f"Random (cold cache): {random_time:.2f}s")
print(f"Random is {random_time/sequential_time:.1f}x slower")