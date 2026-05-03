import 'package:flutter/material.dart';

class SerenityZoomBox extends StatelessWidget {
  const SerenityZoomBox({
    super.key,
    required this.aspectRatio,
    required this.zoom,
    this.zoomBaseSize,
    required this.contentOffset,
    required this.child,
  });

  final double aspectRatio;
  final double zoom;
  final Size? zoomBaseSize;
  final Offset contentOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        if (maxWidth <= 0 || maxHeight <= 0) {
          return const SizedBox.expand();
        }

        var fittedWidth = maxWidth;
        var fittedHeight = fittedWidth / aspectRatio;
        if (fittedHeight > maxHeight) {
          fittedHeight = maxHeight;
          fittedWidth = fittedHeight * aspectRatio;
        }

        final baseSize = zoom > 1.0 && zoomBaseSize != null ? zoomBaseSize! : Size(fittedWidth, fittedHeight);

        final zoomedWidth = baseSize.width * zoom;
        final zoomedHeight = baseSize.height * zoom;
        final left = ((maxWidth - zoomedWidth) / 2) + contentOffset.dx;
        final top = ((maxHeight - zoomedHeight) / 2) + contentOffset.dy;

        return ClipRect(
          child: Stack(
            children: [Positioned(left: left, top: top, width: zoomedWidth, height: zoomedHeight, child: child)],
          ),
        );
      },
    );
  }
}
