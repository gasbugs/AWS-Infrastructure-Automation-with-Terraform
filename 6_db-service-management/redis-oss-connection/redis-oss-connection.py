import redis

# Redis 클러스터 엔드포인트로 연결
redis_host = 'my-redis-0001-001.my-redis.ygzznw.use1.cache.amazonaws.com'
redis_port = 6379

# Redis 클라이언트 생성
client = redis.StrictRedis(
    host=redis_host,
    port=redis_port,
    decode_responses=True  # 문자열 형식으로 응답 디코딩
)

# 데이터 추가
client.set('mykey', 'Hello, Redis!')

# 데이터 읽기
value = client.get('mykey')
print(f"The value of 'mykey' is: {value}")
