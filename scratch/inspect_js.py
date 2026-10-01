from scrapling.fetchers import Fetcher
import re

fetcher = Fetcher()
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaiocean.com/',
}

# Fetch main.js
res = fetcher.get('https://hentaiocean.com/main.js', headers=headers)
js_text = res.body.decode('utf-8', errors='ignore')
print('main.js length:', len(js_text))
matches = re.findall(r'/(?:playlist|series|collection|view|api)[a-zA-Z0-9_/=-]*', js_text)
print('matches in main.js:', set(matches))

# Fetch explore
res2 = fetcher.get('https://hentaiocean.com/explore', headers=headers)
exp_text = res2.body.decode('utf-8', errors='ignore')
matches2 = re.findall(r'href=[\"\'](/[^\"\'\s>]+)[\"\']', exp_text)
print('links in explore:', set(m for m in matches2 if 'watch' not in m and 'assets' not in m))
