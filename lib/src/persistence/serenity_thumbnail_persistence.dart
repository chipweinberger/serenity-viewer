// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellThumbnailPersistence on _SerenityShellState {
  Future<void> _refreshActiveWorkspaceThumbnailIfNeeded() async {
    if (_screen != SerenityScreen.workspace) {
      return;
    }

    final workspace = _activeWorkspaceOrNull;
    final workspaceId = workspace?.id;
    if (workspaceId == null || !_thumbnailDirtyWorkspaces.contains(workspaceId)) {
      return;
    }

    if (_workspaceViewportSize.width <= 0 || _workspaceViewportSize.height <= 0) {
      return;
    }

    await _renderAndPersistWorkspaceThumbnail(workspaceId);
  }

  Future<File> _thumbnailFileForWorkspace(String workspaceId) async {
    final directory = await _thumbnailDirectory();
    return File('${directory.path}/$workspaceId.jpg');
  }

  Future<ui.Image?> _decodeThumbnailSourceImage(String path, {int targetWidth = 320}) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<ui.Image?> _decodeThumbnailVideoFrame(AssetWindowState window, {int targetWidth = 320}) async {
    if (_isRunningInWidgetTest || !Platform.isMacOS) {
      return null;
    }

    final path = window.asset.filePath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      return null;
    }

    try {
      final sourceWidth = window.asset.intrinsicWidth;
      final sourceHeight = window.asset.intrinsicHeight;
      final normalizedCrop = sourceWidth != null && sourceHeight != null && sourceWidth > 0 && sourceHeight > 0
          ? _normalizedVisibleRectForWindow(window, Size(sourceWidth, sourceHeight))
          : const Rect.fromLTWH(0, 0, 1, 1);
      final bytes = await _videoToolsChannel.invokeMethod<Uint8List>('renderVideoThumbnail', {
        'sourcePath': path,
        'positionMs': window.videoPositionMs ?? 0,
        'targetWidth': targetWidth,
        'normalizedCrop': {
          'left': normalizedCrop.left,
          'top': normalizedCrop.top,
          'width': normalizedCrop.width,
          'height': normalizedCrop.height,
        },
      });
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _queueThumbnailRefresh(String workspaceId, {Duration delay = const Duration(milliseconds: 300)}) {
    _thumbnailDirtyWorkspaces.add(workspaceId);
  }

  Future<void> _renderAndPersistWorkspaceThumbnail(String workspaceId) async {
    if (_thumbnailRefreshInFlight.contains(workspaceId)) {
      return;
    }

    if (!_thumbnailRefreshInFlight.contains(workspaceId) && mounted) {
      setState(() {
        _thumbnailRefreshInFlight.add(workspaceId);
      });
    } else {
      _thumbnailRefreshInFlight.add(workspaceId);
    }

    final session = _session;
    if (session == null) {
      _thumbnailRefreshInFlight.remove(workspaceId);
      return;
    }

    final matchingWorkspaces = session.workspaces.where((entry) => entry.id == workspaceId);
    if (matchingWorkspaces.isEmpty) {
      _thumbnailRefreshInFlight.remove(workspaceId);
      return;
    }
    final workspace = matchingWorkspaces.first;

    final thumbnailFile = await _thumbnailFileForWorkspace(workspaceId);
    final bytes = await _buildWorkspaceThumbnailBytes(workspace);
    if (bytes == null) {
      if (mounted) {
        setState(() {
          _thumbnailRefreshInFlight.remove(workspaceId);
        });
      } else {
        _thumbnailRefreshInFlight.remove(workspaceId);
      }
      return;
    }

    await thumbnailFile.writeAsBytes(bytes, flush: true);
    await FileImage(thumbnailFile).evict();
    if (!mounted) {
      _thumbnailDirtyWorkspaces.remove(workspaceId);
      _thumbnailRefreshInFlight.remove(workspaceId);
      return;
    }

    final freshSession = _session;
    if (freshSession == null) {
      setState(() {
        _thumbnailDirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshInFlight.remove(workspaceId);
      });
      return;
    }

    final currentMatching = freshSession.workspaces.where((entry) => entry.id == workspaceId);
    if (currentMatching.isEmpty) {
      setState(() {
        _thumbnailDirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshInFlight.remove(workspaceId);
      });
      return;
    }
    final currentWorkspace = currentMatching.first;
    final nextSession = freshSession.copyWith(
      workspaces: freshSession.workspaces
          .map(
            (entry) => entry.id == workspaceId
                ? entry.copyWith(
                    thumbnailPath: thumbnailFile.path,
                    thumbnailVersion: currentWorkspace.thumbnailVersion + 1,
                  )
                : entry,
          )
          .toList(),
    );

    _updateSession(nextSession);
    if (mounted) {
      setState(() {
        _thumbnailDirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshInFlight.remove(workspaceId);
      });
    } else {
      _thumbnailDirtyWorkspaces.remove(workspaceId);
      _thumbnailRefreshInFlight.remove(workspaceId);
    }
  }

  Future<Uint8List?> _buildWorkspaceThumbnailBytes(WorkspaceState workspace) async {
    const canvasWidth = 560.0;
    const canvasHeight = 360.0;
    const assetCornerRadius = 12.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    canvas.drawColor(SerenityTheme.background, BlendMode.src);

    if (workspace.windows.isEmpty) {
      final emptyPaint = Paint()..color = SerenityTheme.background;
      canvas.drawRect(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), emptyPaint);
    } else {
      final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      final sourceViewportSize = _workspaceViewportSize.width > 0 && _workspaceViewportSize.height > 0
          ? _workspaceViewportSize
          : const Size(canvasWidth, canvasHeight);
      final sourceScale = math.min(canvasWidth / sourceViewportSize.width, canvasHeight / sourceViewportSize.height);
      final sourceOffset = Offset(
        (canvasWidth - (sourceViewportSize.width * sourceScale)) / 2,
        (canvasHeight - (sourceViewportSize.height * sourceScale)) / 2,
      );
      final sourceViewportCenter = sourceViewportSize.center(Offset.zero);

      for (final window in sortedWindows) {
        final rect = Rect.fromLTWH(
          sourceOffset.dx +
              ((sourceViewportCenter.dx +
                      ((window.position.dx - workspace.viewportCenter.dx) * workspace.viewportZoom)) *
                  sourceScale),
          sourceOffset.dy +
              ((sourceViewportCenter.dy +
                      ((window.position.dy - workspace.viewportCenter.dy) * workspace.viewportZoom)) *
                  sourceScale),
          math.max(1, window.size.width * workspace.viewportZoom * sourceScale),
          math.max(1, window.size.height * workspace.viewportZoom * sourceScale),
        );
        if (!rect.overlaps(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight))) {
          continue;
        }
        final roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(assetCornerRadius));
        canvas.save();
        try {
          canvas.clipRRect(roundedRect);
          canvas.drawRect(rect, Paint()..color = Colors.black);

          var paintedMedia = false;
          if (window.asset.type == AssetType.image &&
              window.asset.filePath != null &&
              await File(window.asset.filePath!).exists()) {
            final decoded = await _decodeThumbnailSourceImage(window.asset.filePath!);
            if (decoded != null) {
              paintImage(canvas: canvas, rect: rect, image: decoded, fit: BoxFit.fill);
              paintedMedia = true;
            }
          } else if (window.asset.filePath != null && window.asset.filePath!.isNotEmpty) {
            final decoded = await _decodeThumbnailVideoFrame(window, targetWidth: rect.width.ceil());
            if (decoded != null) {
              paintImage(canvas: canvas, rect: rect, image: decoded, fit: BoxFit.fill);
              paintedMedia = true;
            }
          }

          if (!paintedMedia) {
            canvas.drawRect(rect, Paint()..color = window.asset.color);
          }
        } finally {
          canvas.restore();
        }
      }
    }

    final image = await recorder.endRecording().toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) {
      return null;
    }

    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      return null;
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }
}
