import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_fighter/components/boss_config.dart';

void main() {
  test('boss 1 is easier than boss 3', () {
    final boss1 = BossConfig.forBoss(1);
    final boss3 = BossConfig.forBoss(3);

    expect(boss3.maxHealth, greaterThan(boss1.maxHealth));
    expect(boss3.bulletCount, greaterThan(boss1.bulletCount));
    expect(boss3.bulletSpeed, greaterThan(boss1.bulletSpeed));
    expect(boss3.fireInterval, lessThan(boss1.fireInterval));
    expect(boss3.moveSpeed, greaterThan(boss1.moveSpeed));
  });

  test('boss stats scale with boss number', () {
    final boss5 = BossConfig.forBoss(5);

    expect(boss5.maxHealth, 20 + 5 * 25);
    expect(boss5.title, 'BOSS 5');
    expect(boss5.bulletCount, lessThanOrEqualTo(5));
  });
}
