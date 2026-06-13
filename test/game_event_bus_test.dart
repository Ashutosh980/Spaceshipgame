import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_fighter/utils/game_event_bus.dart';

void main() {
  tearDown(() {
    GameEventBus.instance.clear();
  });

  test('emit delivers event data to listeners', () {
    dynamic received;
    GameEventBus.instance.on(GameEvent.asteroidDestroyed, (event, {data}) {
      received = data;
    });

    final kill = (combo: 3, multiplier: 3, points: 30);
    GameEventBus.instance.emit(GameEvent.asteroidDestroyed, data: kill);

    expect(received, kill);
  });

  test('off removes a specific listener', () {
    var callCount = 0;
    void handler(GameEvent event, {dynamic data}) => callCount++;

    GameEventBus.instance.on(GameEvent.gameOver, handler);
    GameEventBus.instance.off(GameEvent.gameOver, handler);
    GameEventBus.instance.emit(GameEvent.gameOver);

    expect(callCount, 0);
  });

  test('clear removes all listeners', () {
    var callCount = 0;
    GameEventBus.instance.on(GameEvent.levelUp, (_, {data}) => callCount++);
    GameEventBus.instance.clear();
    GameEventBus.instance.emit(GameEvent.levelUp);

    expect(callCount, 0);
  });
}
