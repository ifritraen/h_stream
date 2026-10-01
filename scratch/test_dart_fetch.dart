import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() async {
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': 'https://hentaipro.net/',
  };
  
  final res = await http.get(Uri.parse('https://hentaipro.net/vanilla/'), headers: headers);
  print('Status: ${res.statusCode}, length: ${res.body.length}');
  final doc = html_parser.parse(res.body);
  final articles = doc.querySelectorAll('article.h2-card, .video-card, .item, .post, article');
  print('Articles found: ${articles.length}');
}
