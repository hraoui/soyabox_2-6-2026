class AppConstant {
  // Base URL for API calls - use host IP for mobile simulators
  static String get baseUrl {
    const defaultUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://soyabox.ma',
    );

    // Override at runtime if needed:
    // flutter run --dart-define=API_BASE_URL=https://soyabox.ma
    // flutter run --dart-define=API_BASE_URL=http://localhost:8000
    // flutter run --dart-define=API_BASE_URL=http://192.168.1.XX:8000 (for mobile)
    return defaultUrl;
  }

  static String get apiToken {
    const envToken = String.fromEnvironment('API_TOKEN', defaultValue: '');
    if (envToken.isNotEmpty) return envToken;

    // ✅ Token unique pour toutes les caisses (lecture commandes uniquement)
    return '189a851da7bfc2521cdf172173c6dd7e8418ceabcde5f33ee45797f99858429a';
  }

  static const String windowsUpdateLatestPath =
      '/api/app-updates/windows/latest';
}
