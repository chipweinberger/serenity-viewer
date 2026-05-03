import 'package:flutter/material.dart';

class AssetWindowChrome extends StatelessWidget {
  const AssetWindowChrome({
    super.key,
    required this.flashValue,
    required this.isFocused,
    required this.showHoverFrame,
    required this.assetColor,
    required this.child,
  });

  final double flashValue;
  final bool isFocused;
  final bool showHoverFrame;
  final Color assetColor;
  final Widget child;

  static const double _hoverInset = 3.0;

  @override
  Widget build(BuildContext context) {
    final focusShadowAlpha = isFocused ? 0.26 : 0.18;
    final focusBlurRadius = isFocused ? 34.0 : 22.0;
    final flashScale = 1 + (0.035 * flashValue);
    final assetColorLight = HSLColor.fromColor(assetColor).withLightness(0.82).toColor();
    final assetColorDeep = HSLColor.fromColor(assetColor).withLightness(0.46).toColor();

    return Transform.scale(
      scale: flashScale,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: focusShadowAlpha + (0.08 * flashValue)),
              blurRadius: focusBlurRadius + (12 * flashValue),
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: showHoverFrame
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [assetColorLight, assetColor, assetColorDeep],
                    stops: const [0.0, 0.42, 1.0],
                  )
                : null,
          ),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(showHoverFrame ? _hoverInset : 0),
            child: ClipRRect(borderRadius: BorderRadius.circular(showHoverFrame ? 13 : 16), child: child),
          ),
        ),
      ),
    );
  }
}
