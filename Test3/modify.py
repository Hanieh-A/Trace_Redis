import redis

r = redis.Redis(host="localhost", port=6379)

N = 100

for i in range(N):
    r.set(f"user:{i}", "A" * 1024)

for round in range(20000):
    for i in range(N):
        # value = "B" * 1024

        if i % 2 == 0:
            value = "B" * 512     
        else:
            value = "C" * 4096   

        r.set(f"user:{i}", value)