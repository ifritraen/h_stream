from scrapling.fetchers import Fetcher
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
fetcher = Fetcher()

r = fetcher.get("https://hentai.ht/title/571")
body = r.body.decode('utf-8', errors='ignore')

# Check meta tags
meta_tags = re.findall(r'<meta[^>]+>', body)
print("Meta tags on title 571:")
for m in meta_tags:
    if any(k in m for k in ['image', 'og:', 'twitter:', 'poster', 'thumbnail']):
        print(f"  {m}")

# Check any img tags
imgs = re.findall(r'<img[^>]+>', body)
print(f"Img tags: {imgs}")

# Check any URLs ending with .jpg, .webp, .png
img_urls = re.findall(r'https?://[^\s"\'<>]+\.(?:jpg|jpeg|webp|png)', body)
print(f"Direct image URLs in HTML: {img_urls}")

# Let's inspect og:image or similar on watch page too
rw = fetcher.get("https://hentai.ht/watch/571/1")
wbody = rw.body.decode('utf-8', errors='ignore')
w_imgs = re.findall(r'<meta[^>]+property=[\'"]og:image[\'"][^>]+>', wbody)
print(f"Watch page og:image: {w_imgs}")
