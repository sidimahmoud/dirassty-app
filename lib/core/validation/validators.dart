/// Shared input-validation rules — the actual predicate only. Each
/// screen keeps its own bilingual error message (wording is contextual),
/// but the rule itself lives in exactly one place so it can't drift
/// between screens. Before this existed, self-registration accepted any
/// 4+ character PIN (letters included) and a 3+ character username with
/// no character-set restriction, while parent-created-child screens
/// required an exact 4-digit PIN and `[a-zA-Z0-9_]{3,20}` username — two
/// different rules for what's meant to be the same login credential.
library;

/// A login PIN — always exactly 4 digits. Matches what every login
/// screen and the `register-direct`/`set-student-pin` edge functions
/// expect.
bool isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

/// A student login username — 3 to 20 letters/digits/underscores, the
/// character set `{username}@students.dirassty.internal` (the synthetic
/// login email) can safely contain.
bool isValidUsername(String username) =>
    RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);

const Map<String, String> _latinOf = {
  'ا': 'a',
  'أ': 'a',
  'إ': 'i',
  'آ': 'a',
  'ب': 'b',
  'ت': 't',
  'ث': 'th',
  'ج': 'j',
  'ح': 'h',
  'خ': 'kh',
  'د': 'd',
  'ذ': 'dh',
  'ر': 'r',
  'ز': 'z',
  'س': 's',
  'ش': 'ch',
  'ص': 's',
  'ض': 'd',
  'ط': 't',
  'ظ': 'z',
  'ع': 'a',
  'غ': 'gh',
  'ف': 'f',
  'ق': 'g',
  'ك': 'k',
  'ل': 'l',
  'م': 'm',
  'ن': 'n',
  'ه': 'h',
  'ة': 'a',
  'و': 'ou',
  'ي': 'i',
  'ى': 'a',
  'ئ': 'i',
  'ؤ': 'ou',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'ô': 'o',
  'ö': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

/// A login username suggested from a child's name: the first name in
/// Latin letters (Arabic transliterated, accents dropped, ≤ 12 chars) +
/// [digits], e.g. "Mohamed" / "محمد" + 482 → `mohamed482` / `mhmd482`.
/// Always passes [isValidUsername]. Same shape as the server's
/// generateUniqueUsername (supabase/functions/_shared/username.ts).
String suggestUsername(String name, int digits) {
  final String first = name.trim().split(RegExp(r'\s+')).first.toLowerCase();
  final String latin = first
      .split('')
      .map((c) => _latinOf[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  final String base = latin.length < 2
      ? 'eleve'
      : latin.substring(0, latin.length > 12 ? 12 : latin.length);
  return '$base$digits';
}

/// The 8-digit Mauritanian number from what was typed. People type the 8
/// digits, but "222…", "+222…" and "00222…" (even twice) are accepted too.
/// null if it isn't 8 digits. Same rules as the server (normalizePhone in
/// supabase/functions/_shared/otp.ts, normalize_mr_phone() in SQL).
String? mauritanianPhoneDigits(String input) {
  final String d = input.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^\d{8}$').hasMatch(d)) return d;
  if (RegExp(r'^(00)?222(222)?\d{8}$').hasMatch(d)) {
    return d.substring(d.length - 8);
  }
  return null;
}

/// A Mauritanian phone number (8 digits, see [mauritanianPhoneDigits]).
bool isValidPhone(String phone) => mauritanianPhoneDigits(phone) != null;
