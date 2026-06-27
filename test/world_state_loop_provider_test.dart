import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/features/creative_mode/providers/creative_mode_provider.dart';
import 'package:desk_mario/features/hud/providers/clock_provider.dart';
import 'package:desk_mario/features/notifications/models/notification_severity.dart';
import 'package:desk_mario/features/notifications/providers/background_dim_provider.dart';
import 'package:desk_mario/features/notifications/providers/notification_queue_provider.dart';
import 'package:desk_mario/features/weather/providers/weather_provider.dart';
import 'package:desk_mario/features/world_state/providers/world_state_loop_provider.dart';

ProviderContainer _containerAt(
  DateTime time, {
  WeatherSnapshot weather = const WeatherSnapshot(
    condition: WeatherCondition.clear,
    temperatureC: 21,
  ),
}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWith(
        (ref) => ClockNotifier(initialTime: time, autoTick: false),
      ),
      weatherProvider.overrideWith((ref) => weather),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('derives time phases from clockProvider', () {
    final morning = _containerAt(DateTime(2026, 1, 1, 6));
    expect(
      morning.read(worldStateLoopProvider).timePhase,
      WorldTimePhase.morning,
    );

    final day = _containerAt(DateTime(2026, 1, 1, 12));
    expect(day.read(worldStateLoopProvider).timePhase, WorldTimePhase.day);

    final dusk = _containerAt(DateTime(2026, 1, 1, 18));
    expect(dusk.read(worldStateLoopProvider).timePhase, WorldTimePhase.dusk);

    final night = _containerAt(DateTime(2026, 1, 1, 23));
    expect(night.read(worldStateLoopProvider).timePhase, WorldTimePhase.night);
  });

  test('debug time phase override wins over clockProvider', () {
    final container = _containerAt(DateTime(2026, 1, 1, 12));

    container.read(worldTimePhaseOverrideProvider.notifier).state =
        WorldTimePhase.night;

    expect(
      container.read(worldStateLoopProvider).timePhase,
      WorldTimePhase.night,
    );
  });

  test('maps weather and time into distinct atmosphere recipes', () {
    final rainyNight = _containerAt(
      DateTime(2026, 1, 1, 23),
      weather: const WeatherSnapshot(
        condition: WeatherCondition.rain,
        temperatureC: 18,
      ),
    ).read(worldStateLoopProvider);

    final clearDay = _containerAt(
      DateTime(2026, 1, 1, 12),
      weather: const WeatherSnapshot(
        condition: WeatherCondition.clear,
        temperatureC: 24,
      ),
    ).read(worldStateLoopProvider);

    expect(rainyNight.weather.condition, WeatherCondition.rain);
    expect(
      rainyNight.atmosphere.tintOpacity,
      greaterThan(clearDay.atmosphere.tintOpacity),
    );
    expect(rainyNight.atmosphere.tintOpacity, greaterThanOrEqualTo(0.32));
    expect(
      rainyNight.atmosphere.vignetteOuterOpacity,
      greaterThan(clearDay.atmosphere.vignetteOuterOpacity),
    );
  });

  test('derives inspectable Diorama density from effective creative mode', () {
    final container = _containerAt(DateTime(2026, 1, 1, 12));
    container
        .read(creativeModeProvider.notifier)
        .setManualMode(CreativeMode.diorama);

    final snapshot = container.read(worldStateLoopProvider);

    expect(snapshot.creativeMode, CreativeMode.diorama);
    expect(snapshot.dioramaDensity, DioramaDensity.inspectable);
  });

  test('derives holding alert when severity 4 or dim overlay is active', () {
    final severity4 = _containerAt(DateTime(2026, 1, 1, 12));
    severity4
        .read(notificationQueueProvider.notifier)
        .enqueueSeverity(NotificationSeverity.severity4);

    expect(
      severity4.read(worldStateLoopProvider).alertPhase,
      WorldAlertPhase.holding,
    );

    final dimmed = _containerAt(DateTime(2026, 1, 1, 12));
    dimmed.read(backgroundDimProvider.notifier).state = true;

    expect(
      dimmed.read(worldStateLoopProvider).alertPhase,
      WorldAlertPhase.holding,
    );
  });
}
