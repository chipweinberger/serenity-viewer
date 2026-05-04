import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/window/content/zoom_box.dart';

class ImageSurface extends StatefulWidget {
  const ImageSurface({
    super.key,
    required this.path,
    required this.zoom,
    required this.zoomBaseSize,
    required this.contentOffset,
    this.intrinsicWidth,
    this.intrinsicHeight,
    required this.errorBuilder,
  });

  final String path;
  final double zoom;
  final Size? zoomBaseSize;
  final Offset contentOffset;
  final double? intrinsicWidth;
  final double? intrinsicHeight;
  final WidgetBuilder errorBuilder;

  @override
  State<ImageSurface> createState() => _SerenityImageSurfaceState();
}

class _SerenityImageSurfaceState extends State<ImageSurface> {
  static final Map<String, FileImage> _sharedImageProviders = {};
  static final Map<String, Future<Size?>> _sharedImageSizeFutures = {};
  static final Map<String, Size?> _sharedResolvedImageSizes = {};

  late FileImage _imageProvider;
  Size? _resolvedImageSizeFromDisk;
  bool _isResolvingImageSize = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = _imageProviderForPath(widget.path);
    _resolvedImageSizeFromDisk = _sharedResolvedImageSizes[widget.path];
    if (_resolvedImageSize == null && _resolvedImageSizeFromDisk == null) {
      unawaited(_resolveImageSize());
    }
  }

  @override
  void didUpdateWidget(covariant ImageSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _imageProvider = _imageProviderForPath(widget.path);
    }
    if (oldWidget.path != widget.path ||
        oldWidget.intrinsicWidth != widget.intrinsicWidth ||
        oldWidget.intrinsicHeight != widget.intrinsicHeight) {
      _resolvedImageSizeFromDisk = _sharedResolvedImageSizes[widget.path];
      if (_resolvedImageSize == null && _resolvedImageSizeFromDisk == null) {
        unawaited(_resolveImageSize());
      }
    }
  }

  FileImage _imageProviderForPath(String path) {
    return _sharedImageProviders.putIfAbsent(path, () => FileImage(File(path)));
  }

  Future<Size?> _sharedImageSizeFuture(String path) {
    return _sharedImageSizeFutures.putIfAbsent(path, () async {
      try {
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      } catch (_) {
        return null;
      }
    });
  }

  Future<void> _resolveImageSize() async {
    if (_isResolvingImageSize) {
      return;
    }

    _isResolvingImageSize = true;
    final resolvedSize = await _sharedImageSizeFuture(widget.path);
    _sharedResolvedImageSizes[widget.path] = resolvedSize;
    if (!mounted) {
      return;
    }

    setState(() {
      _resolvedImageSizeFromDisk = resolvedSize;
      _isResolvingImageSize = false;
    });
  }

  Size? get _resolvedImageSize {
    final width = widget.intrinsicWidth;
    final height = widget.intrinsicHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final size = _resolvedImageSize ?? _resolvedImageSizeFromDisk;
    final aspectRatio = size == null || size.width <= 0 || size.height <= 0 ? (4 / 3) : (size.width / size.height);

    return ZoomBox(
      aspectRatio: aspectRatio,
      zoom: widget.zoom,
      zoomBaseSize: widget.zoomBaseSize,
      contentOffset: widget.contentOffset,
      child: Image(
        image: _imageProvider,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null || wasSynchronouslyLoaded) {
            return child;
          }
          return ColoredBox(color: Colors.transparent, child: child);
        },
        errorBuilder: (context, error, stackTrace) => widget.errorBuilder(context),
      ),
    );
  }
}
