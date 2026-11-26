import 'package:shared_preferences/shared_preferences.dart';

/// The last parent who signed in on this device (or opened a child's
/// space from it): their WhatsApp number and first name, so after a
/// child's session the parent comes back with their PIN only — the
/// Welcome card "Bon retour", "Retour à l'espace parent" on the student
/// profile, and the pre-filled parent login. Nothing secret is stored:
/// the PIN is always asked. Forgotten with "Ce n'est pas moi".
class ParentReturnStore {
  const ParentReturnStore();

  static const String _phoneKey = 'parent_return_phone';
  static const String _nameKey = 'parent_return_name';

  Future<void> save(String localPhone, {String? name}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, localPhone);
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_nameKey, name.trim());
    } else {
      await prefs.remove(_nameKey);
    }
  }

  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_phoneKey);

  /// The remembered parent, or null when none.
  Future<RememberedParent?> readParent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? phone = prefs.getString(_phoneKey);
    if (phone == null) return null;
    return RememberedParent(phone: phone, name: prefs.getString(_nameKey));
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
    await prefs.remove(_nameKey);
  }
}

class RememberedParent {
  const RememberedParent({required this.phone, this.name});

  final String phone;
  final String? name;

  /// First name only, for "Bon retour, Ahmed".
  String? get firstName {
    final String? n = name?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(RegExp(r'\s+')).first;
  }

  /// "•••• 45 67" — enough for the parent to recognise their number.
  String get maskedPhone {
    final String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final String last = digits.substring(digits.length - 4);
    return '•••• ${last.substring(0, 2)} ${last.substring(2)}';
  }
}
