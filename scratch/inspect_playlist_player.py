from scrapling.fetchers import Fetcher

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://haho.moe/',
    'Cookie': 'loop-view=thumb;',
}

fetcher = Fetcher()
page = fetcher.get("https://haho.moe/playlist/bwjvsvun/1", headers=headers, timeout=15)
print("Status:", page.status)
print("Title:", page.css('title::text').get())
video = page.css('video, iframe, source')
print(f"Video/Iframe: {[v.attrib.get('src') for v in video]}")
anime_link = page.css('a[href*="/anime/"]')
print("Anime links on player page:", [a.attrib.get('href') for a in anime_link[:3]])
