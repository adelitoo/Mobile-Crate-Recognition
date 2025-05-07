class AppConfig {
  // Base URL for the backend server
  static const String baseUrl = 'http://192.168.1.27:5000';

  // API endpoints
  static String get uploadEndpoint => '$baseUrl/upload';
  static String get clientsEndpoint => '$baseUrl/clients';
  static String get nearestClientEndpoint => '$baseUrl/nearest_client';
  static String get employeesEndpoint => '$baseUrl/employees';
  static String get loginEndpoint => '$baseUrl/login';
}
