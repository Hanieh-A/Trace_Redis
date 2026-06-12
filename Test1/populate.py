import redis

r = redis.Redis(host="localhost", port=6379, decode_responses=True)

N = 1_000_000
VALUE = "x" * 1024   # 1KB

for i in range(N):
    r.set(f"key:{i}", VALUE)