import requests

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

r1 = requests.get('https://api.iwara.tv/search?type=videos&tags=mikumikudance&limit=2', headers=headers)
print("search?tags:", r1.status_code, r1.json().get('count') if r1.status_code == 200 else r1.text[:60])

r2 = requests.get('https://api.iwara.tv/search?type=videos&query=mikumikudance&limit=2', headers=headers)
print("search?query:", r2.status_code, r2.json().get('count') if r2.status_code == 200 else r2.text[:60])
