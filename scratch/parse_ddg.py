import urllib.request
import urllib.parse
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

for q in ['xxxhdhentai', 'simply hentai']:
    data = urllib.parse.urlencode({'q': q}).encode('utf-8')
    req = urllib.request.Request(
        'https://lite.duckduckgo.com/lite/',
        data=data,
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
    )
    with urllib.request.urlopen(req) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
        links = re.findall(r'<a\s+[^>]*href=["\']([^"\']+)["\'][^>]*>(.*?)</a>', html)
        print(f"=== Links for {q} ===")
        for l, t in links:
            if 'duckduckgo' not in l and not l.startswith('?'):
                clean_t = re.sub(r'<[^>]+>', '', t).strip()
                print(f"  {l} -> {clean_t[:60]}")
