import 'package:flutter/foundation.dart';

/// Centralized API configuration for connecting to the CRM Backend server.
class ApiConfig {
  ApiConfig._();

  /// Default Server Domain/Host.
  /// Production Backend hosted on Railway:
  static String _serverHost = 'http://192.168.1.5:5000';
  static int _serverPort = 5000;

  /// Header security key required by backend
  static String apiKey = '26419786fa82542167afdbcf4asdf2130229';

  static String get serverHost => _serverHost;
  static int get serverPort => _serverPort;

  static void updateServerHost(String host, [int port = 443]) {
    _serverHost = host.trim();
    _serverPort = port;
  }

  /// Automatically resolves the most appropriate default base URL
  static String get baseUrl {
    final host = _serverHost.trim();
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host;
    }
    // Check if it's a domain name (e.g. railway.app) vs an IP address
    final isIp =
        host.startsWith('192.') ||
        host.startsWith('10.') ||
        host.startsWith('127.') ||
        host == 'localhost';
    if (!isIp) {
      return 'https://$host';
    }
    if (kIsWeb) {
      return 'http://localhost:$_serverPort';
    }
    return 'http://$host:$_serverPort';
  }

  /// Endpoint URLs
  static String get healthUrl => '$baseUrl/health';
  static String get uploadCardsUrl => '$baseUrl/api/cards/upload';
  static String get customersUrl => '$baseUrl/api/customers';

  /// Standard request headers
  static Map<String, String> get authHeaders => {
    'x-api-key': apiKey,
    'Accept': 'application/json',
  };
}
