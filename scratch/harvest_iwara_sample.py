import sys
import json
import requests
from collections import Counter, defaultdict

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

print("=== Fetching all tags from Iwara API ===")
# Fetch first 10 pages of tags (500 tags)
tag_types = Counter()
tags_by_type = defaultdict(list)
all_tags = []

for page in range(10):
    try:
        r = requests.get(f"https://api.iwara.tv/tags?page={page}&limit=50", headers=headers, timeout=10)
        if r.status_code == 200:
            data = r.json()
            results = data.get("results", [])
            if not results:
                break
            for t in results:
                ttype = t.get("type", "general")
                tag_types[ttype] += 1
                tags_by_type[ttype].append(t)
                all_tags.append(t)
    except Exception as e:
        print(f"Error at page {page}: {e}")
        break

print(f"Fetched {len(all_tags)} tags. Type distribution:")
for ttype, cnt in tag_types.items():
    print(f"  {ttype}: {cnt}")
    print(f"  Sample {ttype}: {[x['id'] for x in tags_by_type[ttype][:10]]}")

print("\n=== Fetching top videos to discover creators and tag usage ===")
creators = {}
tag_counts_in_videos = Counter()

sort_orders = ['views', 'likes', 'trending', 'date']
for sort in sort_orders:
    for page in range(3): # 3 pages of 32 videos each per sort = ~384 video samples
        try:
            r = requests.get(f"https://api.iwara.tv/videos?sort={sort}&page={page}&limit=32", headers=headers, timeout=10)
            if r.status_code == 200:
                data = r.json()
                for v in data.get("results", []):
                    # Creators
                    user = v.get("user")
                    if user and isinstance(user, dict):
                        uid = user.get("id")
                        uname = user.get("name") or user.get("username")
                        username = user.get("username")
                        if uid and uname:
                            if uid not in creators:
                                avatar_id = None
                                if isinstance(user.get("avatar"), dict):
                                    avatar_id = user["avatar"].get("id")
                                creators[uid] = {
                                    "id": uid,
                                    "name": uname,
                                    "username": username,
                                    "avatar_id": avatar_id,
                                    "videos": 0,
                                    "views": 0,
                                    "likes": 0,
                                }
                            creators[uid]["videos"] += 1
                            creators[uid]["views"] += v.get("numViews", 0) or 0
                            creators[uid]["likes"] += v.get("numLikes", 0) or 0
                    
                    # Tags
                    for t in v.get("tags", []):
                        if isinstance(t, dict):
                            tid = t.get("id")
                            ttype = t.get("type")
                            if tid:
                                tag_counts_in_videos[(tid, ttype)] += 1
        except Exception as e:
            print(f"Error fetching videos sort={sort} page={page}: {e}")

print(f"\nUnique creators discovered: {len(creators)}")
top_creators = sorted(creators.values(), key=lambda c: (c['views'], c['likes']), reverse=True)
print("Top 10 Creators by views:")
for c in top_creators[:10]:
    print(f"  {c['name']} (@{c['username']}) - Views: {c['views']}, Likes: {c['likes']}, Videos sampled: {c['videos']}, Avatar: {c['avatar_id']}")

print("\nTop 30 Tags in sampled videos:")
for (tid, ttype), cnt in tag_counts_in_videos.most_common(30):
    print(f"  [{ttype}] {tid}: {cnt}")
