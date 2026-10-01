import sys
sys.stdout.reconfigure(encoding='utf-8')
import json
from scrapling.fetchers import Fetcher

fetcher = Fetcher()
archive_api = "https://web.archive.org/cdx/search/cdx?url=erohentai.tv/*&output=json&limit=50&fl=original,mimetype,statuscode"
res = fetcher.get(archive_api, timeout=10)
print(f"Archive status: {res.status}")
try:
    data = json.loads(res.text)
    print(f"Total archived URLs: {len(data)}")
    for row in data[:30]:
        print(row)
except Exception as e:
    print(f"Error: {e}")
