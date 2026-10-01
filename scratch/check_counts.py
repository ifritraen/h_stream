import requests
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# Check count for different queries
tags = ['mikumikudance', 'koikatsu', 'blender', 'dance', 'genshin_impact', 'mmd']
for t in tags:
    r_v = requests.get(f'https://api.iwara.tv/videos?tags={t}&limit=1', headers=headers)
    r_s = requests.get(f'https://api.iwara.tv/search?type=videos&query={t}&limit=1', headers=headers)
    
    cnt_v = r_v.json().get('count') if r_v.status_code == 200 else 'ERR'
    cnt_s = r_s.json().get('count') if r_s.status_code == 200 else 'ERR'
    print(f"Tag: {t:15} | /videos?tags count: {cnt_v} | /search?query count: {cnt_s}")
