// ignore_for_file: invalid_use_of_protected_member

part of '../../main.dart';

extension _SerenityShellWorkspaceGeometry on _SerenityShellState {
  AssetType? _assetTypeForPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (_SerenityShellState._imageExtensions.contains(extension)) {
      return AssetType.image;
    }
    if (_SerenityShellState._videoExtensions.contains(extension)) {
      return AssetType.video;
    }
    return null;
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  int _colorFromDigest(String value) {
    return _assetColorFromMd5(value).toARGB32();
  }

  double _clampWorkspaceZoom(double zoom) {
    return zoom.clamp(_workspaceMinZoom, _workspaceMaxZoom);
  }

  Offset _clampWorkspaceCenter({required Offset center, required double zoom, required Size viewportSize}) {
    final safeZoom = _clampWorkspaceZoom(zoom);
    final halfVisibleWidth = viewportSize.width <= 0 ? 0.0 : viewportSize.width / (2 * safeZoom);
    final halfVisibleHeight = viewportSize.height <= 0 ? 0.0 : viewportSize.height / (2 * safeZoom);

    final minCenterX = halfVisibleWidth >= _workspaceExtent ? 0.0 : _workspaceMinCoordinate + halfVisibleWidth;
    final maxCenterX = halfVisibleWidth >= _workspaceExtent ? 0.0 : _workspaceMaxCoordinate - halfVisibleWidth;
    final minCenterY = halfVisibleHeight >= _workspaceExtent ? 0.0 : _workspaceMinCoordinate + halfVisibleHeight;
    final maxCenterY = halfVisibleHeight >= _workspaceExtent ? 0.0 : _workspaceMaxCoordinate - halfVisibleHeight;

    return Offset(center.dx.clamp(minCenterX, maxCenterX), center.dy.clamp(minCenterY, maxCenterY));
  }

  Offset _workspaceScreenOffsetForWindow(WorkspaceState workspace, AssetWindowState window, Size viewportSize) {
    final viewportCenter = viewportSize.center(Offset.zero);
    return Offset(
      viewportCenter.dx + ((window.position.dx - workspace.viewportCenter.dx) * workspace.viewportZoom),
      viewportCenter.dy + ((window.position.dy - workspace.viewportCenter.dy) * workspace.viewportZoom),
    );
  }

  void _setWorkspaceViewport({required String workspaceId, Offset? center, double? zoom, bool queueThumbnail = false}) {
    final session = _session;
    if (session == null) {
      return;
    }

    final workspaceMatches = session.workspaces.where((workspace) => workspace.id == workspaceId);
    if (workspaceMatches.isEmpty) {
      return;
    }

    final workspace = workspaceMatches.first;
    final nextZoom = _clampWorkspaceZoom(zoom ?? workspace.viewportZoom);
    final nextCenter = _clampWorkspaceCenter(
      center: center ?? workspace.viewportCenter,
      zoom: nextZoom,
      viewportSize: _workspaceViewportSize,
    );
    final viewportChanged =
        (workspace.viewportCenter.dx - nextCenter.dx).abs() > 0.001 ||
        (workspace.viewportCenter.dy - nextCenter.dy).abs() > 0.001 ||
        (workspace.viewportZoom - nextZoom).abs() > 0.001;
    if (!viewportChanged) {
      return;
    }

    _replaceWorkspace(
      workspace.copyWith(viewportCenterDx: nextCenter.dx, viewportCenterDy: nextCenter.dy, viewportZoom: nextZoom),
      queueThumbnail: queueThumbnail,
    );
    if (!queueThumbnail) {
      _thumbnailDirtyWorkspaces.add(workspaceId);
    }
  }

  Offset _clampWindowPosition(Offset position, Size size) {
    return Offset(
      position.dx.clamp(
        _workspaceMinCoordinate,
        math.max(_workspaceMinCoordinate, _workspaceMaxCoordinate - size.width),
      ),
      position.dy.clamp(
        _workspaceMinCoordinate,
        math.max(_workspaceMinCoordinate, _workspaceMaxCoordinate - size.height),
      ),
    );
  }

  Size _windowSizeByFittingAspect({
    required Size currentSize,
    required double contentWidth,
    required double contentHeight,
  }) {
    const minWidth = 96.0;
    const minHeight = 72.0;
    if (contentWidth <= 0 || contentHeight <= 0) {
      return currentSize;
    }

    final aspectRatio = contentWidth / contentHeight;
    final currentAspectRatio = currentSize.width / currentSize.height;

    if (currentAspectRatio > aspectRatio) {
      final nextWidth = math.max(minWidth, currentSize.height * aspectRatio);
      return Size(math.min(currentSize.width, nextWidth), currentSize.height);
    }

    if (currentAspectRatio < aspectRatio) {
      final nextHeight = math.max(minHeight, currentSize.width / aspectRatio);
      return Size(currentSize.width, math.min(currentSize.height, nextHeight));
    }

    return currentSize;
  }
}
