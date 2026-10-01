import sys
sys.stdout.reconfigure(encoding='utf-8')
from scrapling.fetchers import Fetcher

fetcher = Fetcher()
archive_api = "https://web.archive.org/cdx/search/cdx?url=erohentai.tv&matchType=domain&output=json&limit=100&fl=original,statuscode,timestamp"
res = fetcher.get(archive_api, timeout=15)
print("Text sample:", res.text[:500])
