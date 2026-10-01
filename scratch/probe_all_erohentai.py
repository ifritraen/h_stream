import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

candidates = [
    'https://erohentai.tv',
    'https://erohentai.me',
    'https://erohentai.tube',
    'https://erohentai.net',
    'https://erohentai.org',
    'https://erohentai.to',
    'https://erohentai.is',
    'https://erohentai.cc',
    'https://erohentai.club',
    'https://erohentai.site',
    'https://erohentai.art',
    'https://erohentai.online',
    'https://erohentai.video',
    'https://ero-hentai.tv',
    'https://ero-hentai.net',
    'https://ero-hentai.org',
    'https://ero-hentai.tube',
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
}

fetcher = Fetcher()
for url in candidates:
    try:
        res = fetcher.get(url, headers=headers, timeout=5)
        print(f"SUCCESS: {url} -> status={res.status}, title={res.css('title::text').get()}")
    except Exception as e:
        # short error
        err = str(e)
        if "Could not resolve host" in err:
            err = "DNS resolution failed"
        elif "timed out" in err.lower():
            err = "Timeout"
        print(f"FAILED: {url} -> {err}")
