import 'package:flutter/services.dart';

bool isCommandPressed([Set<LogicalKeyboardKey>? pressedKeys]) {
  final keys = pressedKeys ?? HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.metaLeft) || keys.contains(LogicalKeyboardKey.metaRight);
}

bool isOptionPressed([Set<LogicalKeyboardKey>? pressedKeys]) {
  final keys = pressedKeys ?? HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.altLeft) || keys.contains(LogicalKeyboardKey.altRight);
}
