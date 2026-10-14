import 'package:flutter/material.dart';
import '../../../../core/theme/dirassty_theme.dart';

enum _SymbolCategory { math, physique, sciences }

/// Ported 1:1 from packages/ui/src/SymbolToolbar.tsx — a plain textarea
/// has no keys for √, ², Ω, ⇌, etc., so the student taps a symbol here to
/// insert it at the answer field's cursor position (`onInsert`).
const Map<_SymbolCategory, List<String>> _kSymbols = {
  _SymbolCategory.math: [
    '×',
    '÷',
    '±',
    '√',
    'π',
    '²',
    '³',
    '½',
    '¼',
    '≈',
    '≠',
    '≤',
    '≥',
    '∞',
    '°',
    'Δ',
    '∑',
    '∫',
    '→',
  ],
  _SymbolCategory.physique: [
    'Ω',
    'μ',
    'λ',
    'θ',
    'α',
    'β',
    'γ',
    'φ',
    'ω',
    '°C',
    '°K',
    '→',
    '∝',
    '∇',
    '×10ⁿ',
  ],
  _SymbolCategory.sciences: [
    '→',
    '⇌',
    '°C',
    '₀',
    '₁',
    '₂',
    '₃',
    '₄',
    '₅',
    '₆',
    '⁺',
    '⁻',
    '•',
    '∅',
  ],
};

const Map<_SymbolCategory, String> _kTabLabels = {
  _SymbolCategory.math: '🔢 Math',
  _SymbolCategory.physique: '⚛️ Physique',
  _SymbolCategory.sciences: '🧪 Sciences',
};

class SymbolToolbar extends StatefulWidget {
  const SymbolToolbar({super.key, required this.onInsert});

  final ValueChanged<String> onInsert;

  @override
  State<SymbolToolbar> createState() => _SymbolToolbarState();
}

class _SymbolToolbarState extends State<SymbolToolbar> {
  _SymbolCategory _category = _SymbolCategory.math;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final _SymbolCategory category in _SymbolCategory.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: DirasstySpace.xs),
                child: _CategoryTab(
                  label: _kTabLabels[category]!,
                  selected: category == _category,
                  onTap: () => setState(() => _category = category),
                ),
              ),
          ],
        ),
        const SizedBox(height: DirasstySpace.xs),
        Wrap(
          spacing: DirasstySpace.xs,
          runSpacing: DirasstySpace.xs,
          children: [
            for (final String symbol in _kSymbols[_category]!)
              InkWell(
                onTap: () => widget.onInsert(symbol),
                borderRadius: DirasstyRadius.smallR,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DirasstySpace.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DirasstyColors.surface,
                    borderRadius: DirasstyRadius.smallR,
                    border: Border.all(color: DirasstyColors.line),
                  ),
                  child: Text(symbol, style: const TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DirasstyRadius.pillR,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DirasstySpace.sm, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? DirasstyColors.tealTint : DirasstyColors.surface,
          borderRadius: DirasstyRadius.pillR,
          border: Border.all(
            color: selected ? DirasstyColors.teal : DirasstyColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? DirasstyColors.tealDark : DirasstyColors.textMuted,
          ),
        ),
      ),
    );
  }
}
