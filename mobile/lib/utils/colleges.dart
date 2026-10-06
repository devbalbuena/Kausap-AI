/// Hardcoded FSUU colleges. The short code is what is stored in the database.
class Colleges {
  Colleges._();

  /// code -> full name (keep in sync with backend `COLLEGES` in models/user.py)
  static const Map<String, String> all = {
    'CoN': 'College of Nursing',
    'CEnTech': 'College of Engineering and Technology',
    'CoA': 'College of Accountancy',
    'CIHT': 'College of Innovative Hospitality and Tourism',
    'CORE': 'College of Operations, Resources and Entrepreneurship',
    'CITEC': 'College of Information, Technology, Entertainment and Computing',
    'CTE': 'College of Teacher Education',
    'CAS': 'College of Arts and Sciences',
    'CCJE': 'College of Criminal Justice Education',
  };

  static List<String> get codes => all.keys.toList();

  /// Label for the "not set" legacy bucket.
  static const String notSet = 'Not set';

  /// "CoN – College of Nursing". Returns [notSet] when [code] is null/unknown.
  static String label(String? code) {
    if (code == null || !all.containsKey(code)) return notSet;
    return '$code – ${all[code]}';
  }

  /// Full college name only, or [notSet].
  static String fullName(String? code) {
    if (code == null || !all.containsKey(code)) return notSet;
    return all[code]!;
  }

  /// Distinct brand colors for each college in charts/chips
  static const Map<String, int> colorValues = {
    'CoN': 0xFF0D9488,     // Nursing - Teal/Silver
    'CEnTech': 0xFFEA580C, // Engineering - Orange
    'CoA': 0xFF0284C7,     // Accountancy - Sky Blue
    'CIHT': 0xFF2563EB,    // Hospitality - Royal Blue
    'CORE': 0xFFD97706,    // Operations - Amber/Gold
    'CITEC': 0xFF9333EA,   // Computing/Tech - Purple
    'CTE': 0xFF4F46E5,     // Teacher Education - Indigo
    'CAS': 0xFF16A34A,     // Arts & Sciences - Green
    'CCJE': 0xFFDC2626,    // Criminal Justice - Red
  };

  static int colorValue(String? code) {
    if (code == null) return 0xFF64748B;
    return colorValues[code] ?? 0xFF64748B;
  }
}
