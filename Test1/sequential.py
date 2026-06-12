import redis

r = redis.Redis(host="localhost", port=6379)

N = 100000
REPEAT = 10

for _ in range(REPEAT):
    for i in range(N):
       r.get(f"key:{i}")