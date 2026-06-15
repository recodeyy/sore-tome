import 'package:sero/services/api_service.dart';

/// Service for Admin Dashboard related API calls.
class AdminDashboardService {
  // TODO: Connect to real backend API endpoints
  
  /// Fetches summary statistics for the admin dashboard.
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    // try {
    //   final response = await ApiService.get('/admin/dashboard/summary');
    //   if (response.statusCode == 200) {
    //     return jsonDecode(response.body);
    //   }
    // } catch (e) {
    //   print('Error fetching dashboard summary: $e');
    // }
    return {};
  }

  /// Fetches recent activities for the dashboard.
  static Future<List<dynamic>> getRecentActivities() async {
    // TODO: Implement API call
    return [];
  }
}
