import redis

r = redis.Redis(host="localhost", port=6379)

N = 100_000

for i in range(N):
    r.set(f"key:{i}", "value")