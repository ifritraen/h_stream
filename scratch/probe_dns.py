import urllib.request
import socket

domains = [
    'hentaigalaxy.me',
    'hentaigalaxy.tv',
    'hentaigalaxy.xyz',
    'hentaigalaxy.to',
    'hentaigalaxy.is',
    'hentaigalaxy.cc',
    'hentaigalaxy.io',
    'hentaigalaxy.live',
    'hentaigalaxy.video',
    'hentaigalaxy.tube',
    'hentaigalaxy.vip',
    'hentaigalaxy.site',
    'hentaigalaxy.club',
    'hentaigalaxy.online',
    'hentai-galaxy.com',
    'hentai-galaxy.me',
    'hentai-galaxy.net',
    'galaxyhentai.com',
    'galaxyhentai.net',
    'galaxyhentai.tv',
    'galaxyhentai.me',
]

print("Resolving DNS for candidates:")
for d in domains:
    try:
        ip = socket.gethostbyname(d)
        print(f"  [RESOLVED] {d} -> {ip}")
    except Exception:
        pass
