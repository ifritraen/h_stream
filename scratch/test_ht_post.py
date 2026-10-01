from scrapling.fetchers import Fetcher
import requests

# Try with requests session with custom headers
s = requests.Session()
s.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Origin': 'https://hentai.ht',
    'Referer': 'https://hentai.ht/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
})

# First get homepage to get any cookies / cf tokens
r0 = s.get('https://hentai.ht/')
print("Home GET status:", r0.status_code, "Cookies:", s.cookies.get_dict())

# Then POST age-confirmation
r1 = s.post('https://hentai.ht/api/v1/age-confirmation', data='{}')
print("POST age-confirmation status:", r1.status_code, "Cookies:", s.cookies.get_dict())
print("Response text:", r1.text)

if r1.status_code == 204:
    r2 = s.get('https://hentai.ht/api/v1/catalog/meta')
    print("Catalog meta status:", r2.status_code, "Body:", r2.text[:500])
