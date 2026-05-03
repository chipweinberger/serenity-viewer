// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell.dart';

extension _AppShellThumbnailPersistence on _AppShellState {
  ({Rect mediaRect, Rect visibleRect}) _thumbnailMediaLayoutForWindow({
    required WorkspaceWindowState window,
    required Rect windowRect,
  }) {
    final scale = window.size.width <= 0 ? 1.0 : windowRect.width / window.size.width;
    final fitSize = fitSizeForViewportToAspect(windowRect.size, window.asset.aspectRatio);
    final baseSize = window.zoom > 1.0 && window.zoomBaseSize != null
        ? Size(window.zoomBaseSize!.width * scale, window.zoomBaseSize!.height * scale)
        : fitSize;
    final zoomedWidth = baseSize.width * window.zoom;
    final zoomedHeight = baseSize.height * window.zoom;
    final mediaRect = Rect.fromLTWH(
      windowRect.left + ((windowRect.width - zoomedWidth) / 2) + (window.contentOffset.dx * scale),
      windowRect.top + ((windowRect.height - zoomedHeight) / 2) + (window.contentOffset.dy * scale),
      zoomedWidth,
      zoomedHeight,
    );
    return (mediaRect: mediaRect, visibleRect: mediaRect.intersect(windowRect));
  }

  Future<void> _refreshActiveWorkspaceThumbnailIfNeeded() async {
    if (_uiState.screen != SerenityScreen.workspace) {
      return;
    }

    final workspace = _activeWorkspaceOrNull;
    final workspaceId = workspace?.id;
    if (workspaceId == null || !_thumbnailRefreshState.dirtyWorkspaces.contains(workspaceId)) {
      return;
    }

    if (_workspaceViewportState.viewportSize.width <= 0 || _workspaceViewportState.viewportSize.height <= 0) {
      return;
    }

    await _renderAndPersistWorkspaceThumbnail(workspaceId);
  }

  Future<File> _thumbnailFileForWorkspace(String workspaceId) async {
    final directory = await _sessionPersistenceBridge.thumbnailDirectory();
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

  Future<ui.Image?> _decodeThumbnailVideoFrame(WorkspaceWindowState window, {int targetWidth = 320}) async {
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
          ? normalizedVisibleRectForWindow(window, Size(sourceWidth, sourceHeight))
          : const Rect.fromLTWH(0, 0, 1, 1);
      final bytes = await videoToolsChannel.invokeMethod<Uint8List>('renderVideoThumbnail', {
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
    _thumbnailRefreshState.dirtyWorkspaces.add(workspaceId);
  }

  Future<void> _renderAndPersistWorkspaceThumbnail(String workspaceId) async {
    if (_thumbnailRefreshState.refreshInFlight.contains(workspaceId)) {
      return;
    }

    if (!_thumbnailRefreshState.refreshInFlight.contains(workspaceId) && mounted) {
      setState(() {
        _thumbnailRefreshState.refreshInFlight.add(workspaceId);
      });
    } else {
      _thumbnailRefreshState.refreshInFlight.add(workspaceId);
    }

    final session = _persistenceState.session;
    if (session == null) {
      _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      return;
    }

    final matchingWorkspaces = session.workspaces.where((entry) => entry.id == workspaceId);
    if (matchingWorkspaces.isEmpty) {
      _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      return;
    }
    final workspace = matchingWorkspaces.first;

    final thumbnailFile = await _thumbnailFileForWorkspace(workspaceId);
    final bytes = await _buildWorkspaceThumbnailBytes(workspace);
    if (bytes == null) {
      if (mounted) {
        setState(() {
          _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
        });
      } else {
        _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      }
      return;
    }

    await thumbnailFile.writeAsBytes(bytes, flush: true);
    await FileImage(thumbnailFile).evict();
    if (!mounted) {
      _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
      _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      return;
    }

    final freshSession = _persistenceState.session;
    if (freshSession == null) {
      setState(() {
        _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      });
      return;
    }

    final currentMatching = freshSession.workspaces.where((entry) => entry.id == workspaceId);
    if (currentMatching.isEmpty) {
      setState(() {
        _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
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
        _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
        _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
      });
    } else {
      _thumbnailRefreshState.dirtyWorkspaces.remove(workspaceId);
      _thumbnailRefreshState.refreshInFlight.remove(workspaceId);
    }
  }

  Future<Uint8List?> _buildWorkspaceThumbnailBytes(WorkspaceState workspace) async {
    const canvasWidth = 560.0;
    const canvasHeight = 360.0;
    const assetCornerRadius = 12.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    canvas.drawColor(AppTheme.background, BlendMode.src);

    if (workspace.windows.isEmpty) {
      final emptyPaint = Paint()..color = AppTheme.background;
      canvas.drawRect(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), emptyPaint);
    } else {
      final sortedWindows = [...workspace.windows]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      final sourceViewportSize =
          _workspaceViewportState.viewportSize.width > 0 && _workspaceViewportState.viewportSize.height > 0
          ? _workspaceViewportState.viewportSize
          : const Size(canvasWidth, canvasHeight);
      final sourceScale = math.min(canvasWidth / sourceViewportSize.width, canvasHeight / sourceViewportSize.height);
      final sourceOffset = Offset(
        (canvasWidth - (sourceViewportSize.width * sourceScale)) / 2,
        (canvasHeight - (sourceViewportSize.height * sourceScale)) / 2,
      );
      for (final window in sortedWindows) {
        final rect = workspaceScreenRectForWindow(
          workspace,
          window,
          sourceViewportSize,
          viewportOffset: sourceOffset,
          viewportScale: sourceScale,
        );
        if (!rect.overlaps(const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight))) {
          continue;
        }
        final roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(assetCornerRadius));
        final mediaLayout = _thumbnailMediaLayoutForWindow(window: window, windowRect: rect);
        canvas.save();
        try {
          canvas.clipRRect(roundedRect);
          canvas.drawRect(rect, Paint()..color = window.asset.color);

          var paintedMedia = false;
          if (window.asset.type == AssetType.image &&
              window.asset.filePath != null &&
              await File(window.asset.filePath!).exists()) {
            final decoded = await _decodeThumbnailSourceImage(window.asset.filePath!);
            if (decoded != null) {
              canvas.save();
              canvas.clipRect(rect);
              canvas.drawImageRect(
                decoded,
                Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
                mediaLayout.mediaRect,
                Paint()..filterQuality = FilterQuality.medium,
              );
              canvas.restore();
              paintedMedia = true;
            }
          } else if (window.asset.filePath != null && window.asset.filePath!.isNotEmpty) {
            final decoded = await _decodeThumbnailVideoFrame(window, targetWidth: rect.width.ceil());
            if (decoded != null) {
              if (!mediaLayout.visibleRect.isEmpty) {
                canvas.drawImageRect(
                  decoded,
                  Rect.fromLTWH(0, 0, decoded.width.toDouble(), decoded.height.toDouble()),
                  mediaLayout.visibleRect,
                  Paint()..filterQuality = FilterQuality.medium,
                );
              }
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
