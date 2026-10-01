import urllib.request
import ssl
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def probe(url):
    print(f"=== Probing: {url} ===")
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, context=ctx, timeout=12) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            title = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE)
            print("Title:", title.group(1).strip() if title else "No title")
            
            # Find links
            links = set(re.findall(r'href=[\'"]([^\'"]+)[\'"]', html))
            interesting = [l for l in links if any(k in l.lower() for k in ['tag', 'genre', 'cat', 'studio', 'brand', 'year', 'series', 'playlist', 'type', 'actor', 'director'])]
            print(f"Total links: {len(links)}, Interesting links ({len(interesting)}):")
            for item in sorted(interesting)[:30]:
                print("  ", item)
    except Exception as e:
        print("Error:", e)

probe("https://hentaidb.xyz/")
print("\n" + "="*50 + "\n")
probe("https://hentai.ht/")
