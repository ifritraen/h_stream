import requests

session = requests.Session()
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://hentai.ht/',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
})

# 1. Post age confirmation
r_post = session.post("https://hentai.ht/api/v1/age-confirmation", json={})
print(f"POST age-confirmation status: {r_post.status_code}")
print(f"Response headers: {dict(r_post.headers)}")
print(f"Session cookies: {session.cookies.get_dict()}")

# 2. Check data/t/571.json
r_data = session.get("https://hentai.ht/data/t/571.json")
print(f"data/t/571.json status: {r_data.status_code}")
if r_data.status_code == 200:
    print("Data snippet:", r_data.text[:300])

# 3. Check playback
r_play = session.get("https://hentai.ht/api/v1/playback/571/1?language=en&censorship=censored")
print(f"playback status: {r_play.status_code}")
if r_play.status_code == 200:
    print("Playback data:", r_play.text[:500])
