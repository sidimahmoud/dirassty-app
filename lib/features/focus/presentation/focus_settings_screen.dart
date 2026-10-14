import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/models/focus_settings.dart';
import '../../../core/models/student.dart';
import '../../../core/text/dirassty_dates.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/widgets/auth_errors.dart';
import '../../auth/presentation/widgets/pin_entry.dart';
import '../../parent/application/parent_providers.dart';
import '../../student/application/student_providers.dart';
import '../application/focus_providers.dart';
import '../data/focus_repository.dart';

/// Parent-side editor for one child's focus mode: the switch (dims the
/// windows when off), recurring windows (day circles + start → end via
/// the time picker), the parent code, the iPhone setup note and the log.
///
/// Deviation from FocusSettings.dc.html: "A quitté l'application" has no
/// duration — focus events don't record one yet (TODO(api)).
///
/// design_handoff FocusSettings.dc.html · DESIGN_SPEC §4 "Focus settings".
class FocusSettingsScreen extends ConsumerWidget {
  const FocusSettingsScreen({super.key, required this.studentId});

  static const String path = '/parent/child/:studentId/focus';
  static const String name = 'childFocusSettings';

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<FocusSettings> settings =
        ref.watch(focusSettingsForStudentProvider(studentId));
    final String? childName = ref
        .watch(studentsByParentProvider)
        .valueOrNull
        ?.where((s) => s.id == studentId)
        .firstOrNull
        ?.name;

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(childName ?? l10n.focusMode)),
      body: settings.when(
        loading: () => const _FormSkeleton(),
        error: (_, __) => ErrorState(
          title: l10n.errGeneric,
          onRetry: () =>
              ref.invalidate(focusSettingsForStudentProvider(studentId)),
        ),
        data: (s) => _FocusSettingsForm(initial: s, childName: childName),
      ),
    );
  }
}

/// The same editor, opened from the student's own Profile so a parent
/// can set focus mode up directly on the child's phone (the only option
/// for a self-registered student with no parent account). Once a parent
/// PIN exists, it's required to get in — and verified again server-side
/// on save (see 043_focus_mode_student_device.sql), so the student can't
/// switch focus mode off themselves. The gate shares the focus overlay's
/// attempt limiter (5 misses → 5 min).
class StudentParentalControlScreen extends ConsumerStatefulWidget {
  const StudentParentalControlScreen({super.key});

  static const String path = '/profile/parental-control';
  static const String name = 'studentParentalControl';

  @override
  ConsumerState<StudentParentalControlScreen> createState() =>
      _StudentParentalControlScreenState();
}

class _StudentParentalControlScreenState
    extends ConsumerState<StudentParentalControlScreen> {
  static const PinAttemptLimiter _limiter = PinAttemptLimiter('focus');

  String? _unlockedWithPin;
  String _pin = '';
  bool _wrongPin = false;
  Duration? _lockedFor;

  @override
  void initState() {
    super.initState();
    _limiter.lockRemaining().then((locked) {
      if (mounted) setState(() => _lockedFor = locked);
    });
  }

  Future<void> _onDigit(FocusSettings settings, String digit) async {
    if (_lockedFor != null || _pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _wrongPin = false;
    });
    if (_pin.length < 4) return;
    final String pin = _pin;
    if (settings.verifyPin(pin)) {
      await _limiter.reset();
      if (mounted) setState(() => _unlockedWithPin = pin);
      return;
    }
    final Duration? locked = await _limiter.recordFailure();
    if (!mounted) return;
    setState(() {
      _pin = '';
      _wrongPin = true;
      _lockedFor = locked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Student> student = ref.watch(currentStudentProvider);
    final AsyncValue<FocusSettings>? settings = student.whenOrNull(
      data: (s) => ref.watch(focusSettingsForStudentProvider(s.id)),
    );
    final Widget offline = EmptyState(
        icon: Icons.wifi_off_rounded, title: l10n.needsInternetSettings);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(l10n.parentalControl)),
      body: (settings ?? const AsyncLoading<FocusSettings>()).when(
        loading: () => student.hasError ? offline : const _FormSkeleton(),
        error: (_, __) => offline,
        data: (s) => s.hasPin && _unlockedWithPin == null
            ? _buildGate(l10n, s)
            : _FocusSettingsForm(
                initial: s,
                childName: student.valueOrNull?.name,
                onStudentDevice: true,
                currentPin: _unlockedWithPin,
              ),
      ),
    );
  }

  Widget _buildGate(AppLocalizations l10n, FocusSettings settings) {
    final DirasstyType type = context.dirasstyType;
    final String? error = _lockedFor != null
        ? l10n.pinLocked((_lockedFor!.inSeconds / 60).ceil())
        : (_wrongPin ? l10n.errIncorrectCode : null);
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
      children: [
        const Center(
          child: IconBadge(
            icon: Icons.shield_outlined,
            size: 72,
            background: DirasstyColors.tealTint,
            foreground: DirasstyColors.teal,
          ),
        ),
        const SizedBox(height: DirasstySpace.lg),
        Text(l10n.parentsOnly,
            textAlign: TextAlign.center, style: type.titleSmall),
        const SizedBox(height: DirasstySpace.xs),
        Text(l10n.enterParentCodeBody,
            textAlign: TextAlign.center,
            style: type.bodySmall.copyWith(color: DirasstyColors.textMuted)),
        const SizedBox(height: DirasstySpace.xl),
        PinBoxes(value: _pin, hasError: error != null),
        if (error != null) ...[
          const SizedBox(height: DirasstySpace.sm),
          Text(error,
              textAlign: TextAlign.center,
              style: type.label.copyWith(
                  color: DirasstyColors.error, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: DirasstySpace.xl),
        PinPad(
          onDigit: (d) => _onDigit(settings, d),
          onBackspace: () {
            if (_pin.isNotEmpty) {
              setState(() => _pin = _pin.substring(0, _pin.length - 1));
            }
          },
          enabled: _lockedFor == null,
          backspaceLabel: l10n.backspace,
        ),
      ],
    );
  }
}

class _FocusSettingsForm extends ConsumerStatefulWidget {
  const _FocusSettingsForm({
    required this.initial,
    required this.childName,
    this.onStudentDevice = false,
    this.currentPin,
  });

  final FocusSettings initial;
  final String? childName;

  /// True when opened from the student's own Profile (a parent using the
  /// child's phone): saves go through the PIN-checked RPC, and the lock
  /// is re-applied on this device right away.
  final bool onStudentDevice;

  /// The PIN entered to open this screen on the student's device — the
  /// RPC re-verifies it server-side. Null before any PIN exists.
  final String? currentPin;

  @override
  ConsumerState<_FocusSettingsForm> createState() => _FocusSettingsFormState();
}

class _FocusSettingsFormState extends ConsumerState<_FocusSettingsForm> {
  late bool _enabled = widget.initial.enabled;
  late final List<FocusWindow> _windows = List.of(widget.initial.windows);
  late String? _currentPin = widget.currentPin;
  late bool _hasPin = widget.initial.hasPin;

  /// A new parent code picked in the sheet, applied on save.
  String? _newPin;
  bool _saving = false;
  String? _error;

  /// Saturday first, like the Mauritanian school week (1 = Monday).
  static const List<int> _weekOrder = [6, 7, 1, 2, 3, 4, 5];

  /// Full weekday name for screen readers ("mardi" vs "mercredi" — the
  /// one-letter labels are ambiguous). 2024-01-01 was a Monday (d = 1).
  String _dayName(int d) {
    DirasstyDates.ensureWesternDigits();
    return DateFormat.EEEE(context.isArabicLocale ? 'ar' : 'fr')
        .format(DateTime(2024, 1, d));
  }

  String _dayLabel(int d) {
    const List<String> fr = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const List<String> ar = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    return (context.isArabicLocale ? ar : fr)[d - 1];
  }

  Future<void> _pickTime(int index, {required bool isStart}) async {
    final FocusWindow w = _windows[index];
    final int current = isStart ? w.startMinute : w.endMinute;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final int minute = picked.hour * 60 + picked.minute;
    setState(() {
      _windows[index] = isStart
          ? w.copyWith(startMinute: minute)
          : w.copyWith(endMinute: minute);
    });
  }

  Future<void> _editPin() async {
    final String? pin = await showDirasstyBottomSheet<String>(
      context,
      builder: (_) => const _NewPinSheet(),
    );
    if (pin != null && mounted) {
      setState(() {
        _newPin = pin;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? newPin = _newPin;
    final String? error;
    if (newPin == null && !_hasPin && (_enabled || widget.onStudentDevice)) {
      error = l10n.errFocusPinRequired;
    } else if (_enabled && _windows.isEmpty) {
      error = l10n.errFocusNeedWindow;
    } else if (_windows
        .any((w) => w.days.isEmpty || w.startMinute == w.endMinute)) {
      error = l10n.errFocusWindowInvalid;
    } else {
      error = null;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final FocusSettings updated = widget.initial.copyWith(
      enabled: _enabled,
      windows: _windows,
      pin: newPin,
    );
    try {
      final FocusRepository repo = ref.read(focusRepositoryProvider);
      if (widget.onStudentDevice) {
        final String result = await repo.saveSettingsAsStudent(
          currentPin: _currentPin,
          settings: updated,
          pinChanged: newPin != null,
        );
        if (result != 'ok') {
          setState(() => _error = result == 'pin_locked'
              ? l10n.errParentPinLocked
              : l10n.errParentPinWrong);
          return;
        }
        if (newPin != null) _currentPin = newPin;
        await ref.read(focusLockControllerProvider.notifier).refresh();
      } else {
        await repo.saveSettings(updated);
      }
      _hasPin = _hasPin || newPin != null;
      _newPin = null;
      ref.invalidate(focusSettingsForStudentProvider(updated.studentId));
      if (!mounted) return;
      showDirasstySnackBar(
        context,
        widget.onStudentDevice ? l10n.focusSavedDevice : l10n.focusSavedParent,
      );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.errGeneric);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final bool codeSet = _hasPin || _newPin != null;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen, DirasstySpace.sm, DirasstySpace.screen, DirasstySpace.xxl),
      children: [
        Text(l10n.focusMode, style: type.title),
        const SizedBox(height: DirasstySpace.xs),
        Text(
          l10n.focusIntro(widget.childName ?? ''),
          style: type.bodySmall.copyWith(color: DirasstyColors.textMuted),
        ),
        const SizedBox(height: DirasstySpace.xl),
        DirasstyCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.enableFocus,
                        style: type.subheading.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(_enabled ? l10n.focusStatusOn : l10n.focusOff,
                        style:
                            type.label.copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.xl),
        AnimatedOpacity(
          opacity: _enabled ? 1 : 0.45,
          duration: context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < _windows.length; i++) ...[
                _buildWindow(l10n, i),
                const SizedBox(height: DirasstySpace.lg),
              ],
              DirasstyButton(
                label: l10n.addWindow,
                icon: Icons.add_rounded,
                variant: DirasstyButtonVariant.secondary,
                onPressed: () => setState(
                  () => _windows.add(
                    const FocusWindow(
                      days: {1, 2, 3, 4, 5},
                      startMinute: 17 * 60,
                      endMinute: 19 * 60,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.xl),
        DirasstyCard(
          onTap: _editPin,
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: DirasstyColors.text),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.parentCode,
                        style: type.subheading.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(l10n.parentCodeSub,
                        style:
                            type.label.copyWith(fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              if (codeSet) ...[
                Text('••••',
                    style: type.subheading.copyWith(
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: DirasstySpace.md),
              ],
              Text(
                codeSet ? l10n.edit : l10n.setLogin,
                style: type.label.copyWith(
                    color: DirasstyColors.teal, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: DirasstySpace.lg),
        Container(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
          decoration: const BoxDecoration(
              color: DirasstyColors.tealTint, borderRadius: DirasstyRadius.smallR),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_iphone_rounded,
                  size: 18, color: DirasstyColors.teal),
              const SizedBox(width: DirasstySpace.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: type.label.copyWith(
                        color: DirasstyColors.text, fontWeight: FontWeight.w400),
                    children: [
                      TextSpan(
                        text: '${l10n.onIphone} : ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: l10n.iphoneGuidedAccessSetup),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: DirasstySpace.lg),
          Text(_error!, style: type.label.copyWith(color: DirasstyColors.error)),
        ],
        const SizedBox(height: DirasstySpace.xl),
        DirasstyButton(label: l10n.save, loading: _saving, onPressed: _save),
        if (!widget.onStudentDevice) ...[
          const SizedBox(height: DirasstySpace.xxl),
          Text(l10n.focusLog, style: type.subheading),
          const SizedBox(height: DirasstySpace.md),
          _FocusEventsList(studentId: widget.initial.studentId),
        ],
      ],
    );
  }

  Widget _buildWindow(AppLocalizations l10n, int index) {
    final DirasstyType type = context.dirasstyType;
    final FocusWindow w = _windows[index];
    return DirasstyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.timeWindow(index + 1),
                    style: type.subheading.copyWith(fontSize: 16)),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: DirasstyColors.textMuted),
                onPressed: () => setState(() => _windows.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: DirasstySpace.sm),
          Row(
            children: [
              for (final int d in _weekOrder)
                Expanded(
                    child: _DayCircle(
                  label: _dayLabel(d),
                  semanticLabel: _dayName(d),
                  selected: w.days.contains(d),
                  onTap: () => setState(() {
                    final Set<int> days = Set.of(w.days);
                    days.contains(d) ? days.remove(d) : days.add(d);
                    _windows[index] = w.copyWith(days: days);
                  }),
                )),
            ],
          ),
          const SizedBox(height: DirasstySpace.lg),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: l10n.start,
                  minute: w.startMinute,
                  onTap: () => _pickTime(index, isStart: true),
                ),
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: _TimeField(
                  label: w.crossesMidnight
                      ? '${l10n.end} ${l10n.nextDay}'
                      : l10n.end,
                  minute: w.endMinute,
                  onTap: () => _pickTime(index, isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One day toggle: a 44 pt circle (smaller only when seven don't fit),
/// in a full-width, 44 pt-tall tap cell.
class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: DirasstySize.minTouch,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double size =
                  (constraints.maxWidth - 4).clamp(28.0, DirasstySize.minTouch);
              return Center(
                child: AnimatedContainer(
                  duration:
                      context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? DirasstyColors.ink : DirasstyColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? DirasstyColors.ink : DirasstyColors.line,
                        width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: context.dirasstyType.label.copyWith(
                      color: selected ? Colors.white : DirasstyColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minute,
    required this.onTap,
  });

  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: type.label.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Material(
          color: DirasstyColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: DirasstyRadius.smallR,
            side: BorderSide(color: DirasstyColors.line, width: 1.5),
          ),
          child: InkWell(
            borderRadius: DirasstyRadius.smallR,
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        FocusWindow.formatMinute(minute),
                        textDirection: TextDirection.ltr,
                        style: type.subheading.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter'),
                      ),
                    ),
                    const Icon(Icons.schedule_rounded,
                        size: 18, color: DirasstyColors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// New parent code + confirmation; pops the 4 digits once both match.
class _NewPinSheet extends StatefulWidget {
  const _NewPinSheet();

  @override
  State<_NewPinSheet> createState() => _NewPinSheetState();
}

class _NewPinSheetState extends State<_NewPinSheet> {
  String _pin = '';
  String _confirm = '';
  String? _error;

  void _submit() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!RegExp(r'^\d{4}$').hasMatch(_pin)) {
      setState(() => _error = l10n.errPinFormat);
    } else if (_pin != _confirm) {
      setState(() => _error = l10n.errPinMismatch);
    } else {
      Navigator.of(context).pop(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // showDirasstyBottomSheet already pads for the screen edges and keyboard.
    return Padding(
      padding: EdgeInsetsDirectional.zero,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.parentCode, style: context.dirasstyType.titleSmall),
            const SizedBox(height: DirasstySpace.lg),
            PinField(
              label: l10n.newCode,
              value: _pin,
              onChanged: (v) => setState(() {
                _pin = v;
                _error = null;
              }),
            ),
            const SizedBox(height: DirasstySpace.lg),
            PinField(
              label: l10n.confirmCode,
              value: _confirm,
              errorText: _error,
              onChanged: (v) => setState(() {
                _confirm = v;
                _error = null;
              }),
            ),
            const SizedBox(height: DirasstySpace.xl),
            DirasstyButton(label: l10n.save, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _FocusEventsList extends ConsumerWidget {
  const _FocusEventsList({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String lang = Localizations.localeOf(context).languageCode;
    final AsyncValue<List<FocusEvent>> events =
        ref.watch(focusEventsForStudentProvider(studentId));
    return events.when(
      loading: () => const Skeleton(height: 120, radius: DirasstyRadius.card),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => list.isEmpty
          ? Text(l10n.noFocusEvents,
              style: type.bodySmall.copyWith(color: DirasstyColors.textMuted))
          : DirasstyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (int i, FocusEvent e) in list.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: DirasstyColors.track),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: DirasstySpace.lg, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            e.kind == 'pin_unlock'
                                ? Icons.lock_open_rounded
                                : Icons.exit_to_app_rounded,
                            size: 20,
                            color: e.kind == 'pin_unlock'
                                ? DirasstyColors.teal
                                : DirasstyColors.goldStroke,
                          ),
                          const SizedBox(width: DirasstySpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.kind == 'pin_unlock'
                                      ? l10n.logUnlocked
                                      : l10n.logLeftAppShort,
                                  style: type.subheading.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DirasstyDates.dayMonthYear(e.occurredAt, lang)} · '
                                  '${FocusWindow.formatMinute(e.occurredAt.hour * 60 + e.occurredAt.minute)}',
                                  style: type.label
                                      .copyWith(fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.screen),
      children: const [
        Skeleton(height: 28, width: 200),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 72, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 190, radius: DirasstyRadius.card),
      ],
    );
  }
}
