import sys
import json
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# 1. Test tags sorting and pagination
# Can we sort tags? What sorts exist?
for sort in ['count', 'name', 'popular', 'date']:
    r = requests.get(f'https://api.iwara.tv/tags?sort={sort}&limit=5', headers=headers)
    first_tags = [t['id'] for t in r.json().get('results', [])] if r.status_code == 200 else []
    print(f"tags sort={sort}: {r.status_code}, count={r.json().get('count')}, sample={first_tags}")

# 2. How many tags in total?
# count: 3008 tags!
# We can paginate through tags: page 0..N

# 3. How to filter videos by tag?
# Let's test different parameter names for tag filtering on /videos
for param in ['tags', 'tag', 'tags[]']:
    r = requests.get(f'https://api.iwara.tv/videos?{param}=genshin_impact&limit=5', headers=headers)
    data = r.json() if r.status_code == 200 else {}
    print(f"videos?{param}=genshin_impact: status={r.status_code}, count={data.get('count')}, items={len(data.get('results', []))}")

# 4. How to filter videos by user / creator?
# Let's test with Mary Sue id: c4a89121-1e2a-4b53-9d5b-5fa687c6555d or username user2228613
for user_param in ['user', 'userId', 'username', 'author']:
    r = requests.get(f'https://api.iwara.tv/videos?{user_param}=c4a89121-1e2a-4b53-9d5b-5fa687c6555d&limit=5', headers=headers)
    data = r.json() if r.status_code == 200 else {}
    print(f"videos?{user_param}=UUID: status={r.status_code}, count={data.get('count')}, items={len(data.get('results', []))}")

    r2 = requests.get(f'https://api.iwara.tv/videos?{user_param}=user2228613&limit=5', headers=headers)
    data2 = r2.json() if r2.status_code == 200 else {}
    print(f"videos?{user_param}=username: status={r2.status_code}, count={data2.get('count')}, items={len(data2.get('results', []))}")
