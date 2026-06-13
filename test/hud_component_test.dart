import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_fighter/components/hud_component.dart';

void main() {
  test('recordKill returns base score on first kill', () {
    final hud = HUDComponent();
    final kill = hud.recordKill();

    expect(kill.combo, 1);
    expect(kill.multiplier, 1);
    expect(kill.points, 10);
    expect(hud.comboMultiplier, 1);
  });
}
