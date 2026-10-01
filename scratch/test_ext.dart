import 'package:h_stream/extensions/sources/hentai_pro_extension.dart';

void main() async {
  final ext = HentaiProExtension();
  final items = await ext.fetchTabFeed('recent', 1);
  print('Recent items parsed: ${items.length}');
  if (items.isNotEmpty) {
    print('First item title: ${items[0].title}');
    print('First item cover: ${items[0].cover}');
    print('First item url: ${items[0].url}');
  }
}
