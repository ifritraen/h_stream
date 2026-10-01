// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  final url = "https://animeidhentai.com/trending";
  final res = await http.get(Uri.parse(url), headers: {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://animeidhentai.com/',
  });
  final doc = html_parser.parse(res.body);
  final allLinks = doc.querySelectorAll('a');
  print("Total links: ${allLinks.length}");
  for (final a in allLinks) {
    final href = a.attributes['href'] ?? '';
    final text = a.text.trim();
    if (!href.startsWith('#') && !href.startsWith('/ads') && !href.contains('adtng') && !href.contains('tsyndicate')) {
      final img = a.querySelector('img');
      print("A: href='$href' class='${a.attributes['class']}' text='$text' img='${img?.attributes['src'] ?? img?.attributes['data-src']}'");
    }
  }
}
