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

/// A phone number typed into a form — a minimum digit-length sanity
/// check only; real formatting/validation happens server-side.
bool isValidPhone(String phone) => phone.trim().length >= 8;
