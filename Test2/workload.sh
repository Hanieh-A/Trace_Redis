# 100 entry
for i in $(seq 0 99); do
  redis-cli SET key:$i value
done

for j in $(seq 1 10000); do
  for i in $(seq 0 99); do
    redis-cli GET key:$i > /dev/null
  done
done

# # 1000 entry
# for i in $(seq 0 999); do
#   redis-cli SET key:$i value
# done

# for j in $(seq 1 1000); do
#   for i in $(seq 0 999); do
#     redis-cli GET key:$i > /dev/null
#   done
# done