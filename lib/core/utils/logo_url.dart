/// Builds fallback logo URLs from a channel's official website.
class LogoUrl {
  const LogoUrl._();

  /// Real brand icon served by Google's favicon service. Used when the
  /// iptv-org database has no logo (or the logo URL is dead).
  static String? faviconFor(String? website, {int size = 128}) {
    final domain = _domainOf(website);
    if (domain == null) return null;
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=$size';
  }

  static String? _domainOf(String? website) {
    if (website == null) return null;
    final trimmed = website.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (uri == null) return null;

    var host = uri.host.toLowerCase();
    if (host.isEmpty) return null;
    if (host.startsWith('www.')) host = host.substring(4);
    return host;
  }
}
