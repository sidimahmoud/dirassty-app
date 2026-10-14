import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_lang.dart';
import '../app_language_provider.dart';
import '../../theme/dirassty_theme.dart';

/// Compact trigger for the language picker: current language's monogram +
/// name + a chevron, opening [showLanguagePickerSheet] on tap. Replaces
/// the old FR/عر pill toggles (`_LanguageSwitch`, `LanguageToggle`) — one
/// shared, "fancy" control everywhere the app lets you switch language,
/// on both light surfaces (Profile) and dark/gradient ones (auth header).
class LanguagePickerButton extends ConsumerWidget {
  const LanguagePickerButton({super.key, this.onDark = false});

  /// Whether this sits on a dark/gradient background (auth screens) —
  /// flips the trigger's own colors so it stays readable there, mirroring
  /// how [LanguageToggle] used to.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLang lang = ref.watch(appLanguageProvider);
    final bool isArabic = lang.isArabic;
    final Color fg = onDark ? Colors.white : DirasstyColors.text;
    final Color bg =
        onDark ? Colors.white.withValues(alpha: 0.15) : DirasstyColors.background;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: DirasstyRadius.pillR,
        onTap: () => showLanguagePickerSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DirasstySpace.md,
            vertical: DirasstySpace.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: DirasstyRadius.pillR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == AppLang.fr ? '🇫🇷' : '🇲🇷',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: DirasstySpace.xs),
              Text(
                isArabic ? 'العربية' : 'Français',
                style: (isArabic
                        ? DirasstyType.arabicFont(const TextStyle())
                        : const TextStyle())
                    .copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded,
                  size: 18, color: fg.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the bottom-sheet language picker: two full-width cards (monogram,
/// native name, tagline), the active one highlighted with a check. Picking
/// a language writes straight to [appLanguageProvider], so it takes effect
/// app-wide immediately and persists.
Future<void> showLanguagePickerSheet(BuildContext context, WidgetRef ref) {
  final AppLang current = ref.read(appLanguageProvider);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _LanguagePickerSheet(current: current, ref: ref),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({required this.current, required this.ref});

  final AppLang current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final bool isArabic = current.isArabic;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(DirasstySpace.sm),
        padding: const EdgeInsets.all(DirasstySpace.lg),
        decoration: BoxDecoration(
          color: DirasstyColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DirasstySpace.md),
                decoration: BoxDecoration(
                  color: DirasstyColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isArabic ? 'اختر لغة التطبيق' : 'Choisir la langue',
              textAlign: TextAlign.center,
              style: (isArabic
                      ? DirasstyType.arabicFont(const TextStyle())
                      : const TextStyle())
                  .copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DirasstyColors.text,
              ),
            ),
            const SizedBox(height: DirasstySpace.xl),
            _LanguageCard(
              flag: '🇫🇷',
              nativeName: 'Français',
              tagline: isArabic ? 'اللغة الفرنسية' : "Langue de l'application",
              selected: current == AppLang.fr,
              rtl: false,
              onTap: () => _select(context, AppLang.fr),
            ),
            const SizedBox(height: DirasstySpace.sm),
            _LanguageCard(
              flag: '🇲🇷',
              nativeName: 'العربية',
              tagline: isArabic ? 'لغة التطبيق' : 'Langue arabe',
              selected: current == AppLang.ar,
              rtl: true,
              onTap: () => _select(context, AppLang.ar),
            ),
            const SizedBox(height: DirasstySpace.sm),
          ],
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLang lang) {
    ref.read(appLanguageProvider.notifier).setLanguage(lang);
    Navigator.of(context).pop();
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.flag,
    required this.nativeName,
    required this.tagline,
    required this.selected,
    required this.rtl,
    required this.onTap,
  });

  final String flag;
  final String nativeName;
  final String tagline;
  final bool selected;
  final bool rtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: selected ? DirasstyColors.teal : DirasstyColors.text,
    );
    final TextStyle taglineStyle = TextStyle(
      fontSize: 11,
      color: DirasstyColors.textMuted,
    );

    return Material(
      color: selected ? DirasstyColors.tealTint : DirasstyColors.background,
      borderRadius: DirasstyRadius.cardR,
      child: InkWell(
        borderRadius: DirasstyRadius.cardR,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DirasstySpace.md),
          decoration: BoxDecoration(
            borderRadius: DirasstyRadius.cardR,
            border: Border.all(
              color: selected ? DirasstyColors.teal : DirasstyColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DirasstyColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Text(flag, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nativeName,
                      style: rtl ? DirasstyType.arabicFont(nameStyle) : nameStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tagline,
                      style: rtl
                          ? DirasstyType.arabicFont(taglineStyle)
                          : taglineStyle,
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: DirasstyColors.teal,
                        key: ValueKey('selected'),
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        color: DirasstyColors.textMuted,
                        key: ValueKey('unselected'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
