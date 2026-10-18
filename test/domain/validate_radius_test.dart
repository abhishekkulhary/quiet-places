import 'package:flutter_test/flutter_test.dart';
import 'package:quiet_places/domain/usecases/validate_radius.dart';

void main() {
  group('validateRadius', () {
    test('default 150 m is ok', () {
      expect(validateRadius(150), RadiusValidation.ok);
    });

    test('boundary 50 m is accepted but unreliable', () {
      expect(validateRadius(50), RadiusValidation.unreliable);
    });

    test('99 m is unreliable (under the reliability threshold)', () {
      expect(validateRadius(99), RadiusValidation.unreliable);
      expect(validateRadius(99).isAccepted, isTrue);
    });

    test('exactly 100 m is ok', () {
      expect(validateRadius(100), RadiusValidation.ok);
    });

    test('boundary 1000 m is ok', () {
      expect(validateRadius(1000), RadiusValidation.ok);
    });

    test('below 50 m is too small', () {
      expect(validateRadius(49.9), RadiusValidation.tooSmall);
      expect(validateRadius(0), RadiusValidation.tooSmall);
    });

    test('above 1000 m is too large', () {
      expect(validateRadius(1000.1), RadiusValidation.tooLarge);
    });

    test('null / NaN / infinity are not a number', () {
      expect(validateRadius(null), RadiusValidation.notANumber);
      expect(validateRadius(double.nan), RadiusValidation.notANumber);
      expect(validateRadius(double.infinity), RadiusValidation.notANumber);
    });

    test('clampRadius pins into range', () {
      expect(clampRadius(10), 50);
      expect(clampRadius(5000), 1000);
      expect(clampRadius(300), 300);
    });
  });
}
