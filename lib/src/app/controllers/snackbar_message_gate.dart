class SnackbarMessageGate {
  SnackbarMessageGate({Duration? duplicateCooldown}) : _duplicateCooldown = duplicateCooldown ?? defaultCooldown;

  static const Duration defaultCooldown = Duration(milliseconds: 1200);

  final Duration _duplicateCooldown;

  String? _lastMessage;
  DateTime? _lastShownAt;

  bool shouldShow(String message, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final lastMessage = _lastMessage;
    final lastShownAt = _lastShownAt;

    if (lastMessage == message && lastShownAt != null && timestamp.difference(lastShownAt) < _duplicateCooldown) {
      return false;
    }

    _lastMessage = message;
    _lastShownAt = timestamp;
    return true;
  }
}
