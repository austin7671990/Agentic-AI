import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

Future<String> webSearch(String query) async {
  try {
    final encodedQuery = Uri.encodeComponent(query);
    final url = 'https://html.duckduckgo.com/html/?q=$encodedQuery';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14; SM-F956B)',
      },
    );

    if (response.statusCode != 200) {
      return 'Search failed: HTTP ${response.statusCode}';
    }

    final html = response.body;
    final results = <Map<String, String>>[];

    // Parse DuckDuckGo HTML results
    final resultBlocks = RegExp(
      r'<a rel="nofollow" class="result__a" href="([^"]+)">(.*?)</a>.*?<a class="result__snippet">(.*?)</a>',
      dotAll: true,
    ).allMatches(html);

    final unescape = HtmlUnescape();
    for (final match in resultBlocks.take(5)) {
      final url = match.group(1) ?? '';
      final title = unescape.convert(match.group(2)?.replaceAll(RegExp(r'<[^>]+>'), '') ?? '');
      final snippet = unescape.convert(match.group(3)?.replaceAll(RegExp(r'<[^>]+>'), '') ?? '');
      results.add({
        'title': title.trim(),
        'url': url.trim(),
        'snippet': snippet.trim(),
      });
    }

    if (results.isEmpty) {
      return 'No results found for "$query".';
    }

    final buffer = StringBuffer();
    buffer.writeln('Search results for "$query":');
    buffer.writeln();
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln('${i + 1}. ${r['title']}');
      buffer.writeln('   ${r['snippet']}');
      buffer.writeln('   ${r['url']}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  } catch (e) {
    return 'Search error: $e. Check internet connection.';
  }
}

Future<String> runSandboxCode(String code) async {
  // This is a passthrough - actual sandbox execution is in sandbox_service.dart
  return 'Use the Work Folder screen to run code in the sandbox.';
}