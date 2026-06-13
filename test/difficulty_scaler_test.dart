import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_fighter/components/difficulty_scaler.dart';

void main() {
  test('spawn rate decreases with difficulty and clamps at minimum', () {
    final scaler = DifficultyScaler(difficultyLevel: 1);
    expect(scaler.spawnRate, closeTo(0.75, 0.001));

    scaler.difficultyLevel = 10;
    expect(scaler.spawnRate, closeTo(0.3, 0.001));

    scaler.difficultyLevel = 20;
    expect(scaler.spawnRate, 0.25);
  });

  test('reset restores starting level and timer', () {
    final scaler = DifficultyScaler(difficultyLevel: 5);
    scaler.difficultyLevel = 9;
    scaler.reset(2);

    expect(scaler.difficultyLevel, 2);
    expect(scaler.spawnRate, closeTo(0.7, 0.001));
  });
}
