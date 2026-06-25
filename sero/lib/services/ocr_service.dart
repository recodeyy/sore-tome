import 'dart:convert';
import 'api_client.dart';

class OcrService {
  /// Sends a base64 encoded image to the backend for AI structure extraction.
  /// Returns parsed dictionary including vendor, amount, date, category and note.
  static Future<Map<String, dynamic>> extractReceipt(String base64Image) async {
    try {
      // Ensure the image string starts with data URL schema if backend requires it.
      String formattedImage = base64Image;
      if (!formattedImage.startsWith('data:image/')) {
        // Fallback guess: jpeg. The client should ideally pass the exact format.
        formattedImage = 'data:image/jpeg;base64,$base64Image';
      }

      final res = await ApiClient.request('POST', '/ai/extract-receipt', body: {
        'base64Image': formattedImage,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['parsed'] != null) {
          return data['parsed'] as Map<String, dynamic>;
        } else if (data['partialData'] != null) {
          // Send partial data up if strict adherence failed
          return data['partialData'] as Map<String, dynamic>;
        }
        throw Exception(data['error'] ?? 'Receipt extraction returned invalid payload');
      } else {
        throw Exception('Extraction Error: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to perform Smart Scan: $e');
    }
  }
}
