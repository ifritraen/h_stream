import sys
import json
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# Let's inspect the results of /videos?tags=koikatsu
r = requests.get('https://api.iwara.tv/videos?tags=koikatsu&limit=3', headers=headers)
print("status:", r.status_code)
data = r.json()
print("count:", data.get('count'))
for v in data.get('results', []):
    print("Video:", v.get('title'), "| tags:", [t.get('id') for t in v.get('tags', [])])

# What about /videos?tags[]=koikatsu
r2 = requests.get('https://api.iwara.tv/videos?tags[]=koikatsu&limit=3', headers=headers)
print("\nwith tags[] count:", r2.json().get('count'))
for v in r2.json().get('results', []):
    print("Video:", v.get('title'), "| tags:", [t.get('id') for t in v.get('tags', [])])

# What about /videos?tags=mikumikudance
r3 = requests.get('https://api.iwara.tv/videos?tags=mikumikudance&limit=3', headers=headers)
print("\nmikumikudance count:", r3.json().get('count'))
for v in r3.json().get('results', []):
    print("Video:", v.get('title'), "| tags:", [t.get('id') for t in v.get('tags', [])])

# What about /videos without tag?
r_none = requests.get('https://api.iwara.tv/videos?limit=3', headers=headers)
print("\nno tags filter count:", r_none.json().get('count'))
for v in r_none.json().get('results', []):
    print("Video:", v.get('title'))
