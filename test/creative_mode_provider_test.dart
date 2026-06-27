import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_mario/features/creative_mode/providers/creative_mode_provider.dart';
import 'package:desk_mario/features/notifications/models/notification_severity.dart';
import 'package:desk_mario/features/notifications/providers/notification_queue_provider.dart';

void main() {
  test('manual mode cycles scene to theater to diorama to scene', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.scene,
    );

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(
      container.read(creativeModeProvider).manualMode,
      CreativeMode.theater,
    );
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.theater,
    );

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(
      container.read(creativeModeProvider).manualMode,
      CreativeMode.diorama,
    );
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.diorama,
    );

    container.read(creativeModeProvider.notifier).cycleManualMode();
    expect(container.read(creativeModeProvider).manualMode, CreativeMode.scene);
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.scene,
    );
  });

  test('severity 1 and severity 2 do not force Theater mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(creativeModeProvider.notifier)
        .setManualMode(CreativeMode.diorama);
    container
        .read(notificationQueueProvider.notifier)
        .enqueueSeverity(NotificationSeverity.severity1);
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.diorama,
    );

    container.read(notificationQueueProvider.notifier).completeCurrent();
    container
        .read(notificationQueueProvider.notifier)
        .enqueueSeverity(NotificationSeverity.severity2);
    expect(
      container.read(creativeModeProvider).effectiveMode,
      CreativeMode.diorama,
    );
  });

  test(
    'severity 3 temporarily switches to Theater then restores manual mode',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(creativeModeProvider.notifier)
          .setManualMode(CreativeMode.diorama);
      container
          .read(notificationQueueProvider.notifier)
          .enqueueSeverity(NotificationSeverity.severity3);

      final active = container.read(creativeModeProvider);
      expect(active.manualMode, CreativeMode.diorama);
      expect(active.temporaryMode, CreativeMode.theater);
      expect(active.effectiveMode, CreativeMode.theater);
      expect(active.temporaryLocked, isFalse);

      container.read(notificationQueueProvider.notifier).completeCurrent();

      final restored = container.read(creativeModeProvider);
      expect(restored.temporaryMode, isNull);
      expect(restored.effectiveMode, CreativeMode.diorama);
    },
  );

  test(
    'severity 4 temporarily switches to locked Theater until acknowledged',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(creativeModeProvider.notifier)
          .setManualMode(CreativeMode.scene);
      container
          .read(notificationQueueProvider.notifier)
          .enqueueSeverity(NotificationSeverity.severity4);

      final active = container.read(creativeModeProvider);
      expect(active.effectiveMode, CreativeMode.theater);
      expect(active.temporaryLocked, isTrue);

      container.read(notificationQueueProvider.notifier).completeCurrent();

      final restored = container.read(creativeModeProvider);
      expect(restored.temporaryMode, isNull);
      expect(restored.effectiveMode, CreativeMode.scene);
    },
  );
}
