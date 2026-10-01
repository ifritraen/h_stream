import 'base_extension.dart';

// All 43 Extensions Uniformly Stored in lib/extensions/sources/
import 'sources/hanime_extension.dart';
import 'sources/rule34_extension.dart';
import 'sources/hstream_extension.dart';
import 'sources/hmvmania_extension.dart';
import 'sources/oppai_extension.dart';
import 'sources/hanime1_me_extension.dart';
import 'sources/iwara_net_extension.dart';
import 'sources/hentai_haven_extension.dart';
import 'sources/hentai_city_extension.dart';
import 'sources/hentai_mama_extension.dart';
import 'sources/watch_hentai_extension.dart';
import 'sources/hentaigasm_extension.dart';
import 'sources/hentai_sea_extension.dart';
import 'sources/animeporn_tv_extension.dart';
import 'sources/hentai_tv_extension.dart';
import 'sources/haho_moe_extension.dart';
import 'sources/hentaverse_extension.dart';
import 'sources/hentai_sh_extension.dart';
import 'sources/hentai_ocean_extension.dart';
import 'sources/zhentube_extension.dart';
import 'sources/under_hentai_extension.dart';
import 'sources/hentai_stream_tube_extension.dart';
import 'sources/hentai_play_extension.dart';
import 'sources/only_hentai_stuff_extension.dart';
import 'sources/hentai_world_extension.dart';
import 'sources/my_hentai_movie_extension.dart';
import 'sources/aki_hentai_extension.dart';
import 'sources/hentai_pulse_extension.dart';
import 'sources/hentai_tube_extension.dart';
import 'sources/hentai_fox_extension.dart';
import 'sources/hentai_freak_extension.dart';
import 'sources/hentai_era_extension.dart';
import 'sources/free_hentai_stream_extension.dart';
import 'sources/hentai_zone_extension.dart';
import 'sources/ero_hentai_extension.dart';
import 'sources/hentai_galaxy_extension.dart';
import 'sources/hentai_paradise_extension.dart';
import 'sources/hentai_nexus_extension.dart';
import 'sources/hentai_vibe_extension.dart';
import 'sources/hentai_cloud_extension.dart';
import 'sources/xanimeporn_extension.dart';
import 'sources/hentai_pro_extension.dart';
import 'sources/animeid_hentai_extension.dart';
import 'sources/pornhub_extension.dart';
import 'sources/simply_hentai_extension.dart';
import 'sources/xxxhdhentai_extension.dart';
import 'sources/hentaidb_extension.dart';
import 'sources/hentai_ht_extension.dart';

class ExtensionRegistry {
  static List<HentaiExtension> getAllExtensions() {
    return [
      // Uniform Extension Registry (48 Extensions)
      HanimeExtension(),
      Rule34Extension(),
      HStreamExtension(),
      HmvManiaExtension(),
      OppaiExtension(),
      Hanime1MeExtension(),
      IwaraNetExtension(),
      HentaiHavenExtension(),
      HentaiCityExtension(),
      HentaiMamaExtension(),
      WatchHentaiExtension(),
      HentaigasmExtension(),
      HentaiSeaExtension(),
      AnimepornTvExtension(),
      HentaiTvExtension(),
      HahoMoeExtension(),
      HentaverseExtension(),
      HentaiShExtension(),
      HentaiOceanExtension(),
      ZhentubeExtension(),
      UnderHentaiExtension(),
      HentaiStreamTubeExtension(),
      HentaiPlayExtension(),
      OnlyHentaiStuffExtension(),
      HentaiWorldExtension(),
      MyHentaiMovieExtension(),
      AkiHentaiExtension(),
      HentaiPulseExtension(),
      HentaiTubeExtension(),
      HentaiFoxExtension(),
      HentaiFreakExtension(),
      HentaiEraExtension(),
      FreeHentaiStreamExtension(),
      HentaiZoneExtension(),
      EroHentaiExtension(),
      HentaiGalaxyExtension(),
      HentaiParadiseExtension(),
      HentaiNexusExtension(),
      HentaiVibeExtension(),
      HentaiCloudExtension(),
      XanimepornExtension(),
      HentaiProExtension(),
      AnimeIDHentaiExtension(),
      PornhubExtension(),
      SimplyHentaiExtension(),
      XxxHdhentaiExtension(),
      HentaiDbExtension(),
      HentaiHtExtension(),
    ];
  }
}
