import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/wmo_codes.dart';

void main() {
  group('wmoCodes', () {
    test('maps known codes to descriptions', () {
      expect(wmoCodes[0]?.description, 'Clear sky');
      expect(wmoCodes[3]?.description, 'Overcast');
      expect(wmoCodes[95]?.description, 'Thunderstorm');
    });

    test('every entry has a non-empty description and icon', () {
      for (final entry in wmoCodes.values) {
        expect(entry.description, isNotEmpty);
        expect(entry.icon, isNotEmpty);
      }
    });

    test('unknown code resolves to null (caller handles fallback)', () {
      expect(wmoCodes[7777], isNull);
    });
  });
}
