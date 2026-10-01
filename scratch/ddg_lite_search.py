import urllib.request
import urllib.parse
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

for query in ['xxxhdhentai', 'simply_hentai']:
    print(f"=== Results for {query} ===")
    data = urllib.parse.urlencode({'q': query}).encode('utf-8')
    req = urllib.request.Request(
        'https://lite.duckduckgo.com/lite/',
        data=data,
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            urls = re.findall(r'href="([^"]+)"\s+class="result-link"', html) or re.findall(r'class="result-link"\s+href="([^"]+)"', html)
            snippets = re.findall(r'<td class="result-snippet">\s*(.*?)\s*</td>', html, re.DOTALL)
            for u, s in zip(urls[:5], snippets[:5]):
                clean_s = re.sub(r'<[^>]+>', '', s).strip()
                print('URL:', u)
                print('Snippet:', clean_s[:150])
    except Exception as e:
        print('Error:', e)
