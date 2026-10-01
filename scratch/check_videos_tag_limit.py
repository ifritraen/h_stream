import requests

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

r = requests.get('https://api.iwara.tv/videos?tags=mikumikudance&limit=32', headers=headers)
print("status:", r.status_code)
data = r.json()
print("returned items count:", len(data.get('results', [])))
for v in data.get('results', [])[:5]:
    print(" -", v.get('title'))
