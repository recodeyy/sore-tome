import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ocr_service.dart';

enum SmartScanState { idle, scanning, parsing, confirmation, saving, success, error }

class SmartScanData {
  final SmartScanState state;
  final String errorMessage;
  final Map<String, dynamic>? extractedData;

  SmartScanData({
    this.state = SmartScanState.idle,
    this.errorMessage = "",
    this.extractedData,
  });

  SmartScanData copyWith({
    SmartScanState? state,
    String? errorMessage,
    Map<String, dynamic>? extractedData,
  }) {
    return SmartScanData(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      extractedData: extractedData ?? this.extractedData,
    );
  }
}

class SmartScanNotifier extends StateNotifier<SmartScanData> {
  SmartScanNotifier() : super(SmartScanData());

  /// Trigger the AI Parsing Flow
  Future<void> processReceiptImage(String base64Image) async {
    state = state.copyWith(state: SmartScanState.parsing, errorMessage: "");

    try {
      final result = await OcrService.extractReceipt(base64Image);
      state = state.copyWith(
        extractedData: result,
        state: SmartScanState.confirmation, // ❗ V5.2 Safety Requirement: Must confirm
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        state: SmartScanState.error,
      );
    }
  }

  /// Update individual field during confirmation step
  void updateField(String key, dynamic value) {
    if (state.extractedData != null) {
      final newData = Map<String, dynamic>.from(state.extractedData!);
      newData[key] = value;
      state = state.copyWith(extractedData: newData);
    }
  }

  /// User confirms the edited/reviewed data and submits
  Future<bool> commitTransaction(Future<void> Function(Map<String, dynamic>) saveCallback) async {
    if (state.extractedData == null) return false;

    state = state.copyWith(state: SmartScanState.saving);

    try {
      await saveCallback(state.extractedData!);
      state = state.copyWith(state: SmartScanState.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save transaction: $e',
        state: SmartScanState.error,
      );
      return false;
    }
  }

  void reset() {
    state = SmartScanData();
  }
}

final smartScanProvider = StateNotifierProvider<SmartScanNotifier, SmartScanData>((ref) {
  return SmartScanNotifier();
});
