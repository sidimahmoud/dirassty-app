import 'package:dirassty/core/models/grade.dart';
import 'package:dirassty/core/models/plan.dart';
import 'package:dirassty/features/auth/presentation/trial_offer_screen.dart';
import 'package:dirassty/features/auth/presentation/widgets/auth_errors.dart';
import 'package:dirassty/features/auth/presentation/widgets/pin_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plan _plan(int days, double price, {double discount = 0}) => Plan(
      id: '$days',
      key: 'p$days',
      nameFr: 'Plan',
      nameAr: 'Plan',
      durationDays: days,
      priceMru: price,
      discountPercent: discount,
      isActive: true,
    );

void main() {
  group('PinAttemptLimiter', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('locks after 5 wrong PINs, not before', () async {
      const PinAttemptLimiter limiter = PinAttemptLimiter('student');
      for (int i = 0; i < 4; i++) {
        expect(await limiter.recordFailure(), isNull);
      }
      expect(await limiter.lockRemaining(), isNull);
      expect(await limiter.recordFailure(), PinAttemptLimiter.lockDuration);
      expect(await limiter.lockRemaining(), isNotNull);
    });

    test('reset clears the counter; scopes are independent', () async {
      const PinAttemptLimiter student = PinAttemptLimiter('student');
      const PinAttemptLimiter parent = PinAttemptLimiter('parent');
      for (int i = 0; i < 5; i++) {
        await student.recordFailure();
      }
      expect(await parent.lockRemaining(), isNull);
      await student.reset();
      expect(await student.lockRemaining(), isNull);
    });
  });

  group('grade codes', () {
    test('map every grade to its cycle code', () {
      expect([
        for (int g = 1; g <= 13; g++) gradeCode(g),
      ], [
        'P1', 'P2', 'P3', 'P4', 'P5', 'P6', //
        'C1', 'C2', 'C3', 'C4',
        'L1', 'L2', 'L3',
      ]);
      expect(gradesInCycle(GradeCycle.college), [7, 8, 9, 10]);
      expect(gradeCycle(10), GradeCycle.college);
    });
  });

  group('TrialOfferScreen.cheapestMonthlyPrice', () {
    test('is null with no plan', () {
      expect(TrialOfferScreen.cheapestMonthlyPrice(const []), isNull);
    });

    test('compares plans per 30 days, after discount', () {
      expect(
        TrialOfferScreen.cheapestMonthlyPrice([
          _plan(30, 500),
          _plan(90, 1200), // 400 / month
          _plan(365, 6000, discount: 50), // 3000 → ~247 / month
        ]),
        247,
      );
    });
  });

  test('formatMauritanianPhone groups digits and isolates them LTR', () {
    expect(formatMauritanianPhone('22456789'), '\u2066+222 22 45 67 89\u2069');
  });
}
