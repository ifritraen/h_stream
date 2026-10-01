import sys
import json
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# 1. Total videos
r_all = requests.get('https://api.iwara.tv/videos?limit=1', headers=headers)
print('all videos total count:', r_all.json().get('count'))

# 2. Videos with tag 'genshin_impact' or 'mmd' or 'koikatsu'
for t in ['genshin_impact', 'mmd', 'koikatsu', 'blender', 'dance']:
    r = requests.get(f'https://api.iwara.tv/videos?tags={t}&limit=1', headers=headers)
    print(f'videos?tags={t}: count={r.json().get("count")}')

# 3. What about /search?type=video&tags=... or /search?tags=... or /search?query=...
r_s1 = requests.get('https://api.iwara.tv/search?type=video&query=genshin&limit=1', headers=headers)
print('search video genshin:', r_s1.status_code, r_s1.json().get('count') if r_s1.status_code == 200 else r_s1.text[:100])

# Notice iwara_net_extension.dart has:
# final uri = Uri.parse("$_apiBaseUrl/search").replace(queryParameters: {
#   'type': 'videos', // NOTE: 'videos' plural, let's test!
#   'query': query,
# });
r_s_plural = requests.get('https://api.iwara.tv/search?type=videos&query=genshin&limit=1', headers=headers)
print('search type=videos genshin:', r_s_plural.status_code, r_s_plural.json().get('count') if r_s_plural.status_code == 200 else r_s_plural.text[:100])

# 4. What about search?type=user or type=users
for ut in ['user', 'users', 'profile', 'profiles']:
    r_su = requests.get(f'https://api.iwara.tv/search?type={ut}&query=mmd&limit=3', headers=headers)
    print(f'search type={ut}: status={r_su.status_code}', r_su.json().get('count') if r_su.status_code == 200 else r_su.text[:60])

# 5. Let's check how website www.iwara.tv searches or browses tags / categories
r_web = requests.get('https://www.iwara.tv/videos', headers=headers)
print('web /videos status:', r_web.status_code)
