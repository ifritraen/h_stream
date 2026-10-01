import sys
sys.stdout.reconfigure(encoding='utf-8')
import urllib.request
import json

url = "https://api.allorigins.win/get?url=" + urllib.parse.quote("https://archive.org/wayback/available?url=https://erohentai.tv")
try:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print("Archive available:", data)
except Exception as e:
    print("Error:", e)
