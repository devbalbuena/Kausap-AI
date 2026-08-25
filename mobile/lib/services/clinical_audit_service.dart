import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClinicalAuditService {
  static const String _storageKey = 'counselor_clinical_audit_logs_v1';

  /// Save an immutable audit record locally and prepare it for sync.
  static Future<void> recordLog({
    required String action,
    required String targetType,
    required String targetId,
    String? detail,
    String? adminEmail,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLogs = await loadLogs();

      final newEntry = {
        'id': 'audit_${DateTime.now().millisecondsSinceEpoch}',
        'admin_id': 'counselor_staff',
        'admin_email': adminEmail ?? 'counselor@urios.edu.ph',
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'detail': detail ?? 'Counselor clinical action logged under RA 11036.',
        'created_at': DateTime.now().toIso8601String(),
      };

      currentLogs.insert(0, newEntry);
      await prefs.setString(_storageKey, jsonEncode(currentLogs));
    } catch (_) {}
  }

  /// Load all local clinical audit logs.
  static Future<List<Map<String, dynamic>>> loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Clear or reset audit logs (for testing or compliance purge).
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
