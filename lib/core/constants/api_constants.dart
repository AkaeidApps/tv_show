/// Every remote endpoint used by the app lives here so it can be swapped or
/// mocked in one place.
class ApiConstants {
  const ApiConstants._();

  /// Public, community maintained IPTV database.
  static const String baseUrl = 'https://iptv-org.github.io/api';

  static const String channelsUrl = '$baseUrl/channels.json';
  static const String streamsUrl = '$baseUrl/streams.json';
  static const String logosUrl = '$baseUrl/logos.json';
  static const String countriesUrl = '$baseUrl/countries.json';
  static const String categoriesUrl = '$baseUrl/categories.json';

  static const Duration requestTimeout = Duration(seconds: 20);
}
