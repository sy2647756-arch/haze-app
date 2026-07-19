import 'package:flutter_test/flutter_test.dart';
import 'package:mood_quiz/models/weather.dart';

void main() {
  test('weather score mapping is 1..7 and ordered', () {
    expect(Weather.stormy.score, 1);
    expect(Weather.bright.score, 7);
    expect(Weather.fromKey('hazy'), Weather.hazy);
    expect(Weather.fromKey('unknown'), Weather.hazy);
  });
}
