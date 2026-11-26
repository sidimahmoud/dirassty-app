import 'package:flutter/widgets.dart';

/// True when [text] is mostly Arabic letters — the language a question was
/// written in, whatever the app's language. Digits, math and symbols don't
/// count; a few Latin math letters (x, f, ABC) in an Arabic question don't
/// tip it.
bool isArabicText(String text) {
  int arabic = 0;
  int latin = 0;
  for (final int c in text.runes) {
    if ((c >= 0x0600 && c <= 0x06FF) ||
        (c >= 0x0750 && c <= 0x077F) ||
        (c >= 0x08A0 && c <= 0x08FF) ||
        (c >= 0xFB50 && c <= 0xFDFF) ||
        (c >= 0xFE70 && c <= 0xFEFF)) {
      arabic++;
    } else if ((c >= 0x41 && c <= 0x5A) ||
        (c >= 0x61 && c <= 0x7A) ||
        (c >= 0xC0 && c <= 0x24F)) {
      latin++;
    }
  }
  return arabic > latin;
}

/// Shows learning content (a question, its choices, a hint, an explanation)
/// in the language it's written in: right-to-left with the Arabic font for
/// an Arabic question, left-to-right with the Latin font for a French one —
/// even when the app itself is in the other language. Every
/// `context.dirasstyType` below picks the matching font.
class ContentLanguage extends StatelessWidget {
  const ContentLanguage({required this.arabic, required this.child, super.key});

  /// Detects the language from [sample] (usually the question + choices).
  ContentLanguage.of(String sample, {required this.child, super.key})
      : arabic = isArabicText(sample);

  final bool arabic;
  final Widget child;

  /// The content language set above [context], or null when none.
  static bool? arabicOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ContentLanguageScope>()
      ?.arabic;

  @override
  Widget build(BuildContext context) {
    return _ContentLanguageScope(
      arabic: arabic,
      child: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: child,
      ),
    );
  }
}

class _ContentLanguageScope extends InheritedWidget {
  const _ContentLanguageScope({required this.arabic, required super.child});

  final bool arabic;

  @override
  bool updateShouldNotify(_ContentLanguageScope oldWidget) =>
      oldWidget.arabic != arabic;
}
