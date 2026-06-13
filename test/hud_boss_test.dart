import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_fighter/components/hud_component.dart';

void main() {
  test('recordBossDefeat awards scaled bonus', () {
    final hud = HUDComponent();
    final defeat = hud.recordBossDefeat(2);

    expect(defeat.points, 200);
    expect(defeat.combo, 1);
    expect(defeat.multiplier, 1);
  });
}
