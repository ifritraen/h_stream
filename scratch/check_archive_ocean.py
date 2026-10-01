import urllib.request
import json

urls = [
    'https://web.archive.org/cdx/search/cdx?url=hentaiocean.com/playlist*&output=json',
    'https://web.archive.org/cdx/search/cdx?url=hentaiocean.com/series*&output=json',
    'https://web.archive.org/cdx/search/cdx?url=hentaiocean.com/*&collapse=urlkey&output=json&limit=100',
]

for u in urls:
    try:
        req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            print(u, 'len:', len(data))
            if len(data) > 1:
                for row in data[1:10]:
                    print(' ', row[2])
    except Exception as e:
        print(u, 'err:', e)
