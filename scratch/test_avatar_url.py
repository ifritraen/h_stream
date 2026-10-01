import requests

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# Avatar ID from earlier: 581bd240-2c7b-4e10-8558-0cbd85a4cf8b (from KKD)
# or e10c1f11-7bfb-4766-87f3-4b98850eec77 (from Arisananades)
avatar_id = '581bd240-2c7b-4e10-8558-0cbd85a4cf8b'

candidates = [
    f'https://files.iwara.tv/image/avatar/{avatar_id}/avatar.png',
    f'https://files.iwara.tv/image/avatar/{avatar_id}/avatar.jpg',
    f'https://files.iwara.tv/image/avatar/{avatar_id}/thumbnail-00.jpg',
    f'https://files.iwara.tv/image/thumbnail/{avatar_id}/avatar.png',
    f'https://files.iwara.tv/image/large/{avatar_id}/avatar.png',
    f'https://files.iwara.tv/image/avatar/{avatar_id}',
    f'https://api.iwara.tv/avatar/{avatar_id}',
    f'https://files.iwara.tv/image/profile/{avatar_id}/avatar.png',
]

for url in candidates:
    r = requests.head(url, headers=headers)
    print(f"{url} -> status {r.status_code}")
