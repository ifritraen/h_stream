from scrapling.fetchers import Fetcher
import requests
import json
import re

fetcher = Fetcher()

print("=== 1. Testing HentaiDB Live Playback ===")
r_hdb = fetcher.get("https://hentaidb.xyz/")
print(f"HentaiDB homepage: {r_hdb.status}")
cards = r_hdb.css('a[href^="/s/"]')
print(f"HentaiDB series cards found: {len(cards)}")
if cards:
    sample_href = cards[0].attrib.get('href')
    s_url = f"https://hentaidb.xyz{sample_href}"
    rs = fetcher.get(s_url)
    watch_links = rs.css('a[href*="/watch/"]')
    print(f"HentaiDB watch links on {s_url}: {len(watch_links)}")
    if watch_links:
        w_url = f"https://hentaidb.xyz{watch_links[0].attrib.get('href')}"
        rw = fetcher.get(w_url)
        # Find window.EP
        ep_match = re.search(r'window\.EP\s*=\s*(\{.+?\});', rw.body.decode('utf-8', errors='ignore'))
        if ep_match:
            data = json.loads(ep_match.group(1))
            sources = data.get('src', [])
            print(f"HentaiDB extracted {len(sources)} streams!")
            if sources:
                stream_url = f"https://hentaidb.xyz{sources[0]['file']}"
                # Test stream
                r_stream = requests.get(stream_url, headers={'User-Agent': 'Mozilla/5.0', 'Referer': 'https://hentaidb.xyz/'}, stream=True)
                print(f"HentaiDB stream test ({sources[0]['q']}): HTTP {r_stream.status_code}, Content-Type: {r_stream.headers.get('Content-Type')}")

print("\n=== 2. Testing Hentai.ht Live Playback ===")
s_ht = requests.Session()
s_ht.headers.update({'User-Agent': 'Mozilla/5.0 Chrome/130.0.0.0 Safari/537.36', 'Origin': 'https://hentai.ht', 'Referer': 'https://hentai.ht/'})
s_ht.post("https://hentai.ht/api/v1/age-confirmation", json={})
r_cat = s_ht.get("https://hentai.ht/api/v1/catalog?page=1")
titles = r_cat.json().get('titles', [])
print(f"Hentai.ht titles found: {len(titles)}")
if titles:
    sample = titles[0]
    slug = sample.get('slug') or 'overflow'
    play_url = f"https://hentai.ht/api/v1/playback/{slug}/1?language=ENG%20SUB&censorship=censored"
    r_play = s_ht.get(play_url)
    print(f"Hentai.ht playback status: {r_play.status_code}")
    if r_play.status_code == 200:
        manifest = r_play.json().get('asset', {}).get('manifestUrl')
        m3u8_url = f"https://hentai.ht{manifest}"
        r_m3u8 = s_ht.get(m3u8_url)
        print(f"Hentai.ht HLS manifest status: {r_m3u8.status_code}, Content-Type: {r_m3u8.headers.get('Content-Type')}")
