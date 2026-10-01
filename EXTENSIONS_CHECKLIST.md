# 📋 Extension Implementation Checklist (43 Sites)

> Track progress for each extension scraper, video stream extractor, and taxonomy integration.
> Deeply researched and upgraded from repositories: `yuzono/anime-extensions`, `Kraptor123/Cs-GizliKeyif`, and `phisher98/CXXX`.

---

## 🚀 Progress Summary
- **Total Extensions**: 43
- **Completed**: 43 / 43 (100% COMPLETE! 🎉)
- **Pending**: 0 / 43

---

## 🎯 Full Extension Checklist

| # | Extension Name | Domain | Archetype / Content | Research Source & Stream Technique | Status |
|---|---|---|---|---|:---:|
| 1 | **Hanime.tv** | `https://hanime.tv` | 1080p REST / Astro Feed | Astro SSR HTML feed scraper, CDN webp covers, HLS streams | [x] |
| 2 | **HStream.moe** | `https://hstream.moe` | Subbed & Dubbed Anime | Laravel CSRF token handshake, `/player/api`, direct 1080p/720p MP4 | [x] |
| 3 | **Rule34Video** | `https://rule34video.com` | 3D/MMD Blender Clips | `div.item.thumb`, `search_ajax.php`, direct MP4 stream URL extraction | [x] |
| 4 | **HMV Mania** | `https://hmvmania.com` | 3D MMD Dance 60FPS | ViewTube theme scraping, `li[data-video-source]` 60FPS AV1/MP4 direct streams | [x] |
| 5 | **Oppai.stream** | `https://oppai.stream` | 4K Ultra-HD Remasters | REST API `/api/v1/anime` & `/episodes`, lossless 4K MP4 streams | [x] |
| 6 | **Hanime1.me** | `https://hanime1.me` | Chinese & Japanese Anime | Laravel feed querying, `<video id="player">` multi-bitrate 1080p/720p MP4 | [x] |
| 7 | **Iwara.net** | `https://www.iwara.tv` | 3D VTuber & MMD | Native v2 API, pure Dart SHA-1 signed token resolution, 60FPS master MP4 | [x] |
| 8 | **Hentai Haven** | `https://hentaihaven.xxx` | Classic Flagship Anime | `player-logic/player.php?data=<base64>`, OctopusExtractor resolver | [x] |
| 9 | **HentaiCity** | `https://www.hentaicity.com` | Modern HD Catalog | `fixUrl(hlsUrl)` and direct MP4 extraction from player scripts | [x] |
| 10 | **HentaiMama** | `https://hentaimama.io` | Fast Episode Releases | `POST /wp-admin/admin-ajax.php` (`get_player_contents`), multi-host | [x] |
| 11 | **WatchHentai** | `https://watchhentai.net` | High Bitrate 1080p Anime | Article loop scraping, direct video embeds & download mirrors | [x] |
| 12 | **Hentaigasm** | `https://hentaigasm.com` | Vintage Uncensored Archive | DeTube theme, JWPlayer regex parsing, download mirrors & Streamtape | [x] |
| 13 | **HentaiSea** | `https://hentaisea.com` | Fast Ocean CDN Streaming | DooPlay AJAX handshake, JWPlayer fast CDN MP4 stream extractor | [x] |
| 14 | **AnimePorn TV** | `https://animeporn.tv` | 2D/3D Compilations | Article loop scraping, ISO duration parser, direct Archive.org master MP4 | [x] |
| 15 | **Hentai.tv** | `https://hentai.tv` | Curated TV Broadcasts | JSON-LD schema parser, NHPlayer base64 decode, direct CDN MP4 | [x] |
| 16 | **Haho.moe** | `https://haho.moe` | Franchise Anime Aggregator | `ul.anime-loop.loop > li > a`, sort filters (`vdy-d`, `rel-d`), HTML5 video | [x] |
| 17 | **Hentaverse** | `https://hentaverse.com` | Modern Universe Releases | Next.js catalog scraping, `/hentai/<slug>`, direct preview & master CDN streams | [x] |
| 18 | **Hentai.SH** | `https://hentai.sh` | Dedicated Uncensored | REST API & HTML scrapers, multi-episode extraction, adaptive HLS streams | [x] |
| 19 | **Hentai Ocean** | `https://hentaiocean.com` | Multi-Genre Library | Native JSON API `/api?action=search`, 1080p AV1 master & 720p H.264 streams | [x] |
| 20 | **Zhentube** | `https://zhentube.com` | 3D SFM Tube Shorts | 3D SFM & Blender tube parser, `<video source>`, direct MP4 extraction | [x] |
| 21 | **UnderHentai** | `https://www.underhentai.net` | Underground Classic Vault | Underground vintage vault parser, embed stream servers, direct streams | [x] |
| 22 | **HentaiStream** | `https://tube.hentaistream.com`| Speed Tube Player | Fast buffering tube parser, direct HTML5 video & embed servers | [x] |
| 23 | **HentaiPlay** | `https://hentaiplay.net` | Playlist-Focused Streaming | Playlist series parser, multi-server embed players & mirrors | [x] |
| 24 | **OnlyHentaiStuff** | `https://www.onlyhentaistuff.com` | Studio Specials | Studio series parser, producer specials, embed stream servers | [x] |
| 25 | **HentaiWorld** | `https://hentaiworld.tv` | 1080p Remasters & Packs | CloudStream / Kraptor extractor, direct stream mirrors | [x] |
| 26 | **MyHentaiMovie** | `https://myhentaimovie.com` | Theatrical Feature Movies | Movie length video player streams, high-budget specials, embed mirrors | [x] |
| 27 | **Aki-H** | `https://aki-h.com` / `aki-h.stream` | Sub & Dub Series | `https://aki-h.stream/file/$sid/` & `/v/$sid` with JetPlayer / NowPlay | [x] |
| 28 | **HentaiPulse** | `https://hentaipulse.com` | Community Trending Feeds | Community trending feed parser, weekly popularity charts, embed servers | [x] |
| 29 | **HentaiTube** | `https://hentaitube.online` | Lightweight Tube Player | Lightweight video embeds, fast mobile buffering, direct MP4 streams | [x] |
| 30 | **HentaiFox** | `https://hentaifox.tv` | Tag Discovery | Deep tag taxonomy scraper, character search filters, embed servers | [x] |
| 31 | **HentaiFreak** | `https://hentaifreak.net` | Multi-Mirror Failover | Multi-mirror failover resolver, high-bitrate video stream servers | [x] |
| 32 | **HentaiEra** | `https://hentaiera.com` | Modern 60FPS Series | Modern 60FPS series scraper, high-speed interpolated streams | [x] |
| 33 | **FreeHentaiStream**| `https://freehentaistream.com` | Direct Video Player | Direct video player scraper, multi-mirror fast CDN playback | [x] |
| 34 | **HentaiZone** | `https://hentaizone.me` | Zone-Filtered 4K Remasters | Zone-filtered 4K remasters, curated uncensored video mirrors | [x] |
| 35 | **EroHentai** | `https://erohentai.tv` | 2D/3D Compilations | 2D/3D compilation scraper, studio special series, embed streams | [x] |
| 36 | **HentaiGalaxy** | `https://hentaigalaxy.com` | Cosmic Recommendation | Cosmic recommendation engine, trending franchise clusters, HD streams | [x] |
| 37 | **HentaiParadise** | `https://hentaiparadise.moe`| Moe Aesthetic Series | Moe aesthetic series scraper, pastel uncensored releases, embed streams | [x] |
| 38 | **HentaiNexus** | `https://hentainexus.tv` | Adaptive Multi-Server | Adaptive multi-server streaming network, automated failover mirrors | [x] |
| 39 | **HentaiVibe** | `https://hentaivibe.tv` | Ambient Mood Playlists | Ambient mood playlist scraper, late-night anime streaming, HD mirrors | [x] |
| 40 | **HentaiCloud** | `https://hentaicloud.tv` | Cloud Multi-Bitrate HLS | Cloud multi-bitrate HLS streams, fast global CDN mirrors | [x] |
| 41 | **Xanimeporn** | `https://xanimeporn.com` | Fast Shorts & Series | Fast anime shorts & compilation scraper, high-speed series clips | [x] |
| 42 | **HentaiPro** | `https://hentai.pro` | Uncensored HD Catalog | NHPlayer resolver (`https://nhplayer.com/$url`) from CXXX repo | [x] |
| 43 | **AnimeID Hentai** | `https://animeidhentai.com`| Spanish Subbed & Uncensored | Multi-host video stream embeds from CXXX repo | [x] |

---

## 🛠️ Implementation Protocol per Extension
1. **Feed & Search Extraction**: Parse real covers, titles, durations, tags, and pagination matching the repository selectors.
2. **Stream & Video Resolver**: Reverse-engineer direct MP4 CDNs, HLS `.m3u8` playlists, or embed players with exact headers/cookies.
3. **Validation**: Test live playback on Android device, verify `dart analyze lib` (0 errors), update checkbox in this file.
