import sys
sys.stdout.reconfigure(encoding='utf-8')

from scrapling.fetchers import Fetcher
import json

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.sh/',
}

# 1. Test /api/videos with tag
resp_api = Fetcher.get('https://hentai.sh/api/videos?tags=vanilla&page=1', headers=headers)
print("API status:", resp_api.status)
if resp_api.status == 200:
    data = json.loads(resp_api.body.decode('utf-8'))
    print("Videos count:", len(data.get('videos', [])))
    if data.get('videos'):
        print("Sample video:", data['videos'][0]['title'])

# 2. Test browse page with tag
resp_browse = Fetcher.get('https://hentai.sh/browse?tags=vanilla&page=1', headers=headers)
print("Browse HTML status:", resp_browse.status, "len:", len(resp_browse.body))

# 3. Test playlist page
resp_pl = Fetcher.get('https://hentai.sh/playlist/cmqzjk0wg00a4irsjti3o813v', headers=headers)
print("Playlist status:", resp_pl.status, "len:", len(resp_pl.body))
