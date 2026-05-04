class WorkspaceLinkParser {
  WorkspaceLinkParser._();

  static final RegExp _urlPattern = RegExp(r"""((?:https?:\/\/)|(?:www\.))[^\s<>"']+""", caseSensitive: false);

  static List<String> extractUrls(String text) {
    final uniqueUrls = <String>{};
    final urls = <String>[];
    for (final match in _urlPattern.allMatches(text)) {
      final normalized = normalizeUrl(match.group(0));
      if (normalized == null || !uniqueUrls.add(normalized)) {
        continue;
      }
      urls.add(normalized);
    }
    return urls;
  }

  static String? normalizeUrl(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    var value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    while (value.isNotEmpty && '.,!?;:\'"'.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }

    while (value.isNotEmpty && '([{<'.contains(value[0])) {
      value = value.substring(1);
    }

    while (value.isNotEmpty && ')]}>'.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }

    if (value.startsWith('www.')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) || uri.host.isEmpty) {
      return null;
    }

    return uri.toString();
  }
}
