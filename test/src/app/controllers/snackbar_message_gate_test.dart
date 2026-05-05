import 'package:flutter_test/flutter_test.dart';
import 'package:serenity_viewer/src/app/controllers/snackbar_message_gate.dart';

void main() {
  group('SnackbarMessageGate', () {
    test('suppresses duplicate messages during the cooldown window', () {
      final gate = SnackbarMessageGate(duplicateCooldown: const Duration(seconds: 1));
      final start = DateTime(2026, 1, 1, 12);

      expect(gate.shouldShow('No supported image or video files were found in that selection.', now: start), isTrue);
      expect(
        gate.shouldShow(
          'No supported image or video files were found in that selection.',
          now: start.add(const Duration(milliseconds: 500)),
        ),
        isFalse,
      );
    });

    test('allows different messages and retries after the cooldown expires', () {
      final gate = SnackbarMessageGate(duplicateCooldown: const Duration(seconds: 1));
      final start = DateTime(2026, 1, 1, 12);

      expect(gate.shouldShow('First message', now: start), isTrue);
      expect(gate.shouldShow('Second message', now: start.add(const Duration(milliseconds: 100))), isTrue);
      expect(gate.shouldShow('Second message', now: start.add(const Duration(seconds: 2))), isTrue);
    });
  });
}
