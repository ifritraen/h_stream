from scrapling.fetchers import Fetcher

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaitube.online/',
}

fetcher = Fetcher()
url = "https://www.hentaitube.online/tvshows/night-shift-nurses-kranke/"
page = fetcher.get(url, headers=HEADERS, timeout=10)

print("Status:", page.status)
# Check sgeneros, tags, categories, metadata
for a in page.css('.sgeneros a, .genres a, .tagclouds a, .custom_fields a, .data a'):
    print(f"Meta link: text='{a.text}' href='{a.attrib.get('href')}'")

# Check episode list or player iframe
print("Player / episodes:")
for ep in page.css('.episodios a, #seasons a, .numerando'):
    print(f"  Episode: text='{ep.text}' href='{ep.attrib.get('href')}'")
