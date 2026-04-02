class ApiConstants {
  // Change this to your Laravel API URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String user = '/auth/user';
  
  // Log endpoints
  static const String logs = '/logs';
  static String logById(int id) => '/logs/$id';
  static String logPhotos(int id) => '/logs/$id/photos';
  static String logQuotePdf(int id) => '/logs/$id/quote/pdf';

  // Call endpoints
  static const String calls = '/calls';
  static String callById(int id) => '/calls/$id';
  static String callAttachMemo(int id) => '/calls/$id/memo';
}
