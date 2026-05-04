import 'dart:math' as math;

import 'package:serenity_viewer/src/foundation/app_constants.dart';

String newSerenityId(String prefix) {
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
}

int assetColorValueFromDigest(String value) {
  return assetColorFromMd5(value).toARGB32();
}
