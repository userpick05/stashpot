import 'package:http/http.dart' as http;

/// Fetches lightweight link metadata (title + preview image) for "add by link".
/// Best-effort: if the site blocks us or has no tags, falls back to the domain
/// name so a saved recipe is always openable in the browser.
class LinkPreviewService {
  final http.Client _client;
  LinkPreviewService([http.Client? client]) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  Future<({String name, String? image})> fetchMeta(String url) async {
    try {
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0 (compatible; Stashpot/1.0)'},
      ).timeout(_timeout);

      if (resp.statusCode == 200) {
        final html = resp.body;
        final title = _ogTag(html, 'og:title') ??
            _titleTag(html) ??
            _domain(url);
        final image = _ogTag(html, 'og:image');
        return (name: title, image: image);
      }
    } catch (_) {
      // ignore — fall through to domain fallback
    }
    return (name: _domain(url), image: null);
  }

  String? _ogTag(String html, String prop) {
    final p1 = RegExp(
      '<meta[^>]+(?:property|name)=["\']$prop["\'][^>]+content=["\']([^"\']*)["\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (p1 != null) return _unescape(p1.group(1)!.trim());

    final p2 = RegExp(
      '<meta[^>]+content=["\']([^"\']*)["\'][^>]+(?:property|name)=["\']$prop["\']',
      caseSensitive: false,
    ).firstMatch(html);
    if (p2 != null) return _unescape(p2.group(1)!.trim());
    return null;
  }

  String? _titleTag(String html) {
    final m = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true, caseSensitive: false)
        .firstMatch(html);
    if (m == null) return null;
    final t = _unescape(m.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim());
    return t.isEmpty ? null : t;
  }

  String _domain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
