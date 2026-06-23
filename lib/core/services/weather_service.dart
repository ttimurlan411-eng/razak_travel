import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  WeatherService({
    http.Client? client,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? _defaultApiKey;

  WeatherService._() : this();

  static final WeatherService instance = WeatherService._();

  static const String _defaultApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
  );
  static const String _weatherHost = 'api.openweathermap.org';

  final http.Client _client;
  final String _apiKey;

  Future<WeatherData> getWeatherByLatLng({
    required double lat,
    required double lng,
    String languageCode = 'en',
  }) async {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw 'invalid_coordinates';
    }

    if (_apiKey.trim().isEmpty) {
      throw 'weather_api_key_missing';
    }

    final response = await _client.get(
      Uri.https(
        _weatherHost,
        '/data/2.5/weather',
        {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'appid': _apiKey,
          'units': 'metric',
          if (languageCode.trim().isNotEmpty) 'lang': languageCode.trim(),
        },
      ),
      headers: const {
        'Accept': 'application/json',
      },
    );

    final body = response.body.trim();
    final decoded = body.isEmpty ? null : jsonDecode(body);
    final payload = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        throw message;
      }

      throw 'weather_fetch_failed';
    }

    return WeatherData.fromJson(payload);
  }
}

class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.iconCode,
  });

  final double temperature;
  final String condition;
  final String iconCode;

  String get iconUrl {
    if (iconCode.isEmpty) {
      return '';
    }

    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weatherList = json['weather'];

    final mainData = main is Map ? Map<String, dynamic>.from(main) : null;
    final primaryWeather = weatherList is List && weatherList.isNotEmpty
        ? weatherList.first
        : null;
    final weatherData = primaryWeather is Map
        ? Map<String, dynamic>.from(primaryWeather)
        : null;

    final rawTemp = mainData?['temp'];
    final temperature = rawTemp is num
        ? rawTemp.toDouble()
        : double.tryParse(rawTemp?.toString() ?? '');
    final description = weatherData?['description']?.toString().trim() ?? '';
    final mainCondition = weatherData?['main']?.toString().trim() ?? '';
    final iconCode = weatherData?['icon']?.toString().trim() ?? '';

    if (temperature == null) {
      throw 'weather_fetch_failed';
    }

    return WeatherData(
      temperature: temperature,
      condition: description.isNotEmpty ? description : mainCondition,
      iconCode: iconCode,
    );
  }
}
