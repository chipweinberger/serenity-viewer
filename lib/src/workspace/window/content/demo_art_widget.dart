import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/asset.dart';

class DemoArtWidget extends StatelessWidget {
  const DemoArtWidget({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SerenityDemoArtPainter(asset: asset),
      child: const SizedBox.expand(),
    );
  }
}

class _SerenityDemoArtPainter extends CustomPainter {
  const _SerenityDemoArtPainter({required this.asset});

  final Asset asset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseColor = asset.color;
    final accent = HSLColor.fromColor(baseColor).withLightness(0.84).withSaturation(0.58).toColor();
    final deep = HSLColor.fromColor(baseColor).withLightness(0.28).withSaturation(0.44).toColor();

    final background = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, baseColor.withValues(alpha: 0.95), deep],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final softCircle = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.22), size.shortestSide * 0.22, softCircle);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.2), size.shortestSide * 0.16, softCircle);

    final diagonal = Path()
      ..moveTo(size.width * 0.08, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.44, size.width * 0.56, size.height * 0.61)
      ..quadraticBezierTo(size.width * 0.76, size.height * 0.78, size.width * 0.96, size.height * 0.52)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(diagonal, Paint()..color = Colors.black.withValues(alpha: 0.16));

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height * 0.14, size.width * 0.76, size.height * 0.72),
      Radius.circular(size.shortestSide * 0.08),
    );
    canvas.drawRRect(frameRect, Paint()..color = Colors.white.withValues(alpha: 0.2));

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = math.max(1.5, size.shortestSide * 0.012)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index++) {
      final y = size.height * (0.26 + (index * 0.1));
      canvas.drawLine(Offset(size.width * 0.2, y), Offset(size.width * 0.74, y), stripePaint);
    }

    final highlightRect = Rect.fromLTWH(size.width * 0.58, size.height * 0.18, size.width * 0.18, size.height * 0.52);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(size.shortestSide * 0.05)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0.05)],
        ).createShader(highlightRect),
    );

    if (asset.type == AssetType.video) {
      final center = Offset(size.width * 0.5, size.height * 0.5);
      final radius = size.shortestSide * 0.14;
      canvas.drawCircle(center, radius, Paint()..color = Colors.black.withValues(alpha: 0.28));
      final playPath = Path()
        ..moveTo(center.dx - (radius * 0.28), center.dy - (radius * 0.46))
        ..lineTo(center.dx - (radius * 0.28), center.dy + (radius * 0.46))
        ..lineTo(center.dx + (radius * 0.48), center.dy)
        ..close();
      canvas.drawPath(playPath, Paint()..color = Colors.white.withValues(alpha: 0.92));
    }
  }

  @override
  bool shouldRepaint(covariant _SerenityDemoArtPainter oldDelegate) {
    return oldDelegate.asset.id != asset.id ||
        oldDelegate.asset.colorValue != asset.colorValue ||
        oldDelegate.asset.type != asset.type;
  }
}
