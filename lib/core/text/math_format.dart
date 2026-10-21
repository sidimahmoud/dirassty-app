const Map<String, String> _kSuperscript = {
  '0': '⁰',
  '1': '¹',
  '2': '²',
  '3': '³',
  '4': '⁴',
  '5': '⁵',
  '6': '⁶',
  '7': '⁷',
  '8': '⁸',
  '9': '⁹',
  '+': '⁺',
  '-': '⁻',
};

const Map<String, String> _kSubscript = {
  '0': '₀',
  '1': '₁',
  '2': '₂',
  '3': '₃',
  '4': '₄',
  '5': '₅',
  '6': '₆',
  '7': '₇',
  '8': '₈',
  '9': '₉',
  '+': '₊',
  '-': '₋',
  'n': 'ₙ',
  'k': 'ₖ',
  'm': 'ₘ',
  'i': 'ᵢ',
  'p': 'ₚ',
  'j': 'ⱼ',
};

String _toSuper(String s) =>
    s.split('').map((c) => _kSuperscript[c] ?? c).join();

String _toSub(String s) => s.split('').map((c) => _kSubscript[c] ?? c).join();

/// Ported line-for-line (same order — order matters, e.g. `\frac` must be
/// rewritten before the catch-all stray-command stripper runs) from
/// `cleanMathForDisplay` in packages/shared/src/lib/mathFormat.ts. Turns
/// raw LaTeX-ish markup the AI sometimes writes (`\frac{1}{2}`, `x^2`,
/// `\sqrt{x}`) into plain Unicode a student can actually read, since this
/// app has no LaTeX renderer. Distinct from the video studio's narration
/// cleanup (which turns the same markup into spoken words) — this one is
/// for text a student reads, not text read aloud.
String cleanMathForDisplay(String text) {
  if (text.isEmpty) return text;

  String out = text;

  // $...$ / $$...$$ delimiters — just remove them, keep the content.
  out = out.replaceAll(RegExp(r'\$\$?'), '');

  // \frac{a}{b} -> (a)/(b)
  out = out.replaceAllMapped(
    RegExp(r'\\frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}'),
    (m) => '(${m[1]})/(${m[2]})',
  );
  // \sqrt[n]{a} / \sqrt{a} -> ⁿ√(a) / √(a)
  out = out.replaceAllMapped(
    RegExp(r'\\sqrt\s*(?:\[([^\]]*)\])?\s*\{([^{}]*)\}'),
    (m) => '${m[1] != null ? '${_toSuper(m[1]!)}√' : '√'}(${m[2]})',
  );
  // Bare (non-LaTeX) "sqrt(...)" / "sqrt[n](...)" — the AI sometimes writes
  // plain ASCII instead of LaTeX, which the rule above doesn't catch since
  // it requires a backslash and braces.
  out = out.replaceAllMapped(
    RegExp(
      r'\bsqrt\s*(?:\[([^\[\]]*)\])?\s*\(([^()]*)\)',
      caseSensitive: false,
    ),
    (m) => '${m[1] != null ? '${_toSuper(m[1]!)}√' : '√'}(${m[2]})',
  );
  out = out.replaceAll(RegExp(r'\\times|\\cdot'), '×');
  out = out.replaceAll(RegExp(r'\\div'), '÷');
  out = out.replaceAll(RegExp(r'\\pi'), 'π');
  out = out.replaceAll(RegExp(r'\\%'), '%');
  // \left / \right — LaTeX sizing hints; drop them, any literal ( ) that
  // follows stays as-is.
  out = out.replaceAll(RegExp(r'\\left|\\right'), '');
  out = out
      .replaceAll(RegExp(r'\\infty'), '∞')
      .replaceAll(RegExp(r'\\leq'), '≤')
      .replaceAll(RegExp(r'\\geq'), '≥')
      .replaceAll(RegExp(r'\\neq'), '≠')
      .replaceAll(RegExp(r'\\pm'), '±');

  // Exponents: ^2, ^{2}, ^{12} -> ², ¹²
  out = out.replaceAllMapped(
    RegExp(r'\^\{([^{}]+)\}'),
    (m) => _toSuper(m[1]!),
  );
  out = out.replaceAllMapped(RegExp(r'\^([0-9+-]+)'), (m) => _toSuper(m[1]!));
  // Subscripts: _2, _{12}
  // u_{n+1} → uₙ₊₁ (only when every character has a subscript form);
  // other braced indices ("_{max}"): just drop the braces.
  out = out.replaceAllMapped(
    RegExp(r'_\{([0-9+\-nkmipj]+)\}'),
    (m) => _toSub(m[1]!),
  );
  out = out.replaceAllMapped(RegExp(r'_\{([^{}]+)\}'), (m) => '_${m[1]}');
  out = out.replaceAllMapped(RegExp(r'_([0-9+-]+)'), (m) => _toSub(m[1]!));
  // Single-letter index: u_n, a_k (not "x_max").
  out = out.replaceAllMapped(
    RegExp(r'_([nkmipj])(?![A-Za-z])'),
    (m) => _toSub(m[1]!),
  );

  // Spelled-out symbols the AI sometimes writes instead of the symbol
  // itself. Whole words only ("pied", "épice", "alphabet" untouched).
  out = out
      .replaceAll('<=>', '⇔')
      .replaceAll('<=', '≤')
      .replaceAll('>=', '≥')
      .replaceAll('!=', '≠')
      .replaceAll('=>', '⇒')
      .replaceAll('->', '→')
      .replaceAll('+/-', '±')
      .replaceAll(RegExp(r'\bpi\b', caseSensitive: false), 'π')
      .replaceAll(RegExp(r'\b[Dd]elta\b'), 'Δ')
      .replaceAll(RegExp(r'\bOmega\b'), 'Ω')
      .replaceAll(RegExp(r'\balpha\b'), 'α')
      .replaceAll(RegExp(r'\bbeta\b'), 'β')
      .replaceAll(RegExp(r'\bgamma\b'), 'γ')
      .replaceAll(RegExp(r'\btheta\b'), 'θ')
      .replaceAll(RegExp(r'\blambda\b'), 'λ')
      .replaceAll(RegExp(r'\bsigma\b'), 'σ')
      .replaceAll(RegExp(r'\bomega\b'), 'ω');

  // Any remaining stray LaTeX command — drop rather than leave
  // "\command" visible on screen.
  out = out.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
  // Leftover grouping braces.
  out = out.replaceAll(RegExp(r'[{}]'), '');
  // Collapse doubled/stray whitespace left behind by removals.
  out = out.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();

  return out;
}
