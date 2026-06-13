/// Scaling stats for each boss encounter.
/// Boss 1 appears at level 10, Boss 2 at level 20, and so on.
class BossConfig {
  final int bossNumber;
  final int maxHealth;
  final double moveSpeed;
  final double fireInterval;
  final int bulletCount;
  final double bulletSpeed;
  final double bulletSpread;

  const BossConfig({
    required this.bossNumber,
    required this.maxHealth,
    required this.moveSpeed,
    required this.fireInterval,
    required this.bulletCount,
    required this.bulletSpeed,
    required this.bulletSpread,
  });

  factory BossConfig.forBoss(int bossNumber) {
    final n = bossNumber.clamp(1, 99);
    return BossConfig(
      bossNumber: n,
      maxHealth: 20 + n * 25,
      moveSpeed: 70 + n * 12,
      fireInterval: (1.8 - n * 0.1).clamp(0.45, 1.8),
      bulletCount: (1 + (n - 1) ~/ 2).clamp(1, 5),
      bulletSpeed: 200 + n * 22,
      bulletSpread: 0.15 + n * 0.03,
    );
  }

  String get title => 'BOSS $bossNumber';
}
