abstract final class CountryDisplay {
  static const _names = <String, String>{
    'BD': 'Bangladesh',
    'GB': 'United Kingdom',
    'IN': 'India',
    'PK': 'Pakistan',
    'US': 'United States',
    'CA': 'Canada',
    'AU': 'Australia',
    'BR': 'Brazil',
    'FR': 'France',
    'DE': 'Germany',
    'IT': 'Italy',
    'JP': 'Japan',
    'KR': 'South Korea',
    'MX': 'Mexico',
    'NP': 'Nepal',
    'NG': 'Nigeria',
    'PH': 'Philippines',
    'RU': 'Russia',
    'SA': 'Saudi Arabia',
    'ES': 'Spain',
    'TR': 'Turkey',
    'AE': 'United Arab Emirates',
  };

  static String name(String code) =>
      _names[code.toUpperCase()] ?? code.toUpperCase();

  static String flag(String code) {
    final normalized = code.toUpperCase();
    if (normalized.length != 2 ||
        normalized.codeUnits.any((unit) => unit < 65 || unit > 90)) {
      return '🌐';
    }
    return String.fromCharCodes(
      normalized.codeUnits.map((unit) => 0x1F1E6 + unit - 65),
    );
  }
}
