import sys
import json
import requests

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://www.iwara.tv/',
}

# Test creator Inwerwm
# Let's get inwerwm user id
r_u = requests.get('https://api.iwara.tv/profile/inwerwm', headers=headers)
print("profile/inwerwm status:", r_u.status_code)
if r_u.status_code == 200:
    udata = r_u.json()
    user = udata.get('user', {})
    uid = user.get('id')
    print("Inwerwm ID:", uid, "Name:", user.get('name'), "Avatar:", user.get('avatar'))
    
    # Query videos for this user
    r_v = requests.get(f'https://api.iwara.tv/videos?user={uid}&limit=5', headers=headers)
    print("videos for Inwerwm status:", r_v.status_code, "count:", r_v.json().get('count'))
    for v in r_v.json().get('results', []):
        print("  - Video:", v.get('title'), "views:", v.get('numViews'), "likes:", v.get('numLikes'))
