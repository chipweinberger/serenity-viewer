// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellImportAndLoadPlan on _SerenityShellState {
  SerenityLoadPlan _buildLoadPlan() {
    final session = _session!;
    final loadedAssetIds = <String>{};
    var loadedImages = 0;
    var loadedShortVideos = 0;
    var loadedLongVideos = 0;

    void retainWindow(AssetWindowState window) {
      if (!loadedAssetIds.add(window.asset.id)) {
        return;
      }

      switch (window.asset.type) {
        case AssetType.image:
          loadedImages += 1;
          break;
        case AssetType.video:
          if (window.asset.videoLengthCategory == VideoLengthCategory.short) {
            loadedShortVideos += 1;
          } else {
            loadedLongVideos += 1;
          }
          break;
      }
    }

    final activeWorkspace = _activeWorkspaceOrNull;
    if (activeWorkspace == null) {
      return const SerenityLoadPlan(loadedAssetIds: {}, loadedImages: 0, loadedShortVideos: 0, loadedLongVideos: 0);
    }

    final activeWorkspaceId = activeWorkspace.id;
    for (final window in activeWorkspace.windows) {
      retainWindow(window);
    }

    final hiddenWorkspaces = session.workspaces.where((workspace) => workspace.id != activeWorkspaceId).toList()
      ..sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));

    for (final workspace in hiddenWorkspaces) {
      for (final window in workspace.windows) {
        if (window.asset.type == AssetType.image) {
          if (loadedImages >= session.imageLoadLimit) {
            continue;
          }
          retainWindow(window);
          continue;
        }

        if (window.asset.videoLengthCategory == VideoLengthCategory.short) {
          if (loadedShortVideos >= session.shortVideoLoadLimit) {
            continue;
          }
          retainWindow(window);
          continue;
        }

        if (loadedLongVideos >= session.longVideoLoadLimit) {
          continue;
        }
        retainWindow(window);
      }
    }

    return SerenityLoadPlan(
      loadedAssetIds: loadedAssetIds,
      loadedImages: loadedImages,
      loadedShortVideos: loadedShortVideos,
      loadedLongVideos: loadedLongVideos,
    );
  }

  int _unloadedCountForWorkspace(WorkspaceState workspace, SerenityLoadPlan loadPlan) {
    return workspace.windows.where((window) => !loadPlan.loadedAssetIds.contains(window.asset.id)).length;
  }

  WorkspaceMediaCounts _mediaCountsForWorkspace(WorkspaceState workspace) {
    return WorkspaceMediaCounts(
      images: workspace.windows.where((window) => window.asset.type == AssetType.image).length,
      shortVideos: workspace.windows
          .where((window) => window.asset.videoLengthCategory == VideoLengthCategory.short)
          .length,
      longVideos: workspace.windows
          .where((window) => window.asset.videoLengthCategory == VideoLengthCategory.long)
          .length,
      links: workspace.links.length,
    );
  }

  void _recordFolder(String path, {int weight = 1}) {
    final session = _session!;
    final normalized = Directory(path).absolute.path;
    final nextKnownFolders = [...session.knownFolders];
    if (!nextKnownFolders.contains(normalized)) {
      nextKnownFolders.add(normalized);
    }

    final nextPopularity = Map<String, int>.from(session.folderPopularity);
    nextPopularity[normalized] = (nextPopularity[normalized] ?? 0) + weight;

    _session = session.copyWith(knownFolders: nextKnownFolders, folderPopularity: nextPopularity);
  }

  Future<void> _pickAndImportAssets() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Media',
          extensions: [..._SerenityShellState._imageExtensions, ..._SerenityShellState._videoExtensions],
        ),
      ],
    );

    await _importFiles(files);
  }

  Future<void> _importFiles(List<XFile> files) async {
    if (files.isEmpty || _session == null) {
      return;
    }

    final supported = files.where((file) => _assetTypeForPath(file.path) != null).toList();
    if (supported.isEmpty) {
      _showMessage('No supported image or video files were found in that selection.');
      return;
    }

    final limited = supported.take(200).toList();

    final workspace = _activeWorkspace;
    final nextWindows = [...workspace.windows];
    final existingAssetDigests = nextWindows.map((window) => window.asset.md5).toSet();
    var nextZ = nextWindows.fold<int>(0, (value, item) => math.max(value, item.zIndex));
    var offsetIndex = 0;
    var skippedDuplicateCount = 0;

    for (final xfile in limited) {
      final type = _assetTypeForPath(xfile.path);
      if (type == null) {
        continue;
      }

      final file = File(xfile.path);
      if (!await file.exists()) {
        continue;
      }

      final videoProbe = type == AssetType.video ? await _probeVideoFile(file) : null;
      var importType = type;
      var importPath = xfile.path;
      var importFilename = xfile.name;
      String? importMd5;
      var videoDurationMs =
          videoProbe?.durationMs ?? (type == AssetType.video ? await _videoDurationMsForFile(file) : null);
      var imageDimensions = type == AssetType.image ? await _imageDimensionsForFile(file) : null;
      final videoDimensions = videoProbe?.width != null && videoProbe?.height != null
          ? Size(videoProbe!.width!.toDouble(), videoProbe.height!.toDouble())
          : null;

      if (type == AssetType.video && videoProbe?.isSingleFrame == true) {
        final shouldConvert = await _confirmSingleFrameConversion(xfile.name);
        if (shouldConvert) {
          final conversion = await _exportVideoFrameToJpeg(
            sourcePath: xfile.path,
            probe: videoProbe!,
            positionMs: videoDurationMs == null ? null : math.min(videoDurationMs, 1000),
            promptBeforeOverwrite: true,
          );
          if (conversion != null) {
            importType = AssetType.image;
            importPath = conversion.path;
            importFilename = conversion.filename;
            importMd5 = conversion.md5;
            imageDimensions = Size(conversion.width, conversion.height);
            videoDurationMs = null;
          }
        }
      }

      final importFile = File(importPath);
      final digest = importMd5 ?? await _md5ForFile(importFile);
      if (existingAssetDigests.contains(digest)) {
        skippedDuplicateCount += 1;
        continue;
      }

      final fileBookmark = await _createFileBookmark(importPath);
      final directory = importFile.parent.path;
      _recordFolder(directory, weight: 2);
      nextZ += 1;
      final basePlacement = _clampWindowPosition(
        Offset(
          workspace.viewportCenter.dx - 180 + (offsetIndex * 26),
          workspace.viewportCenter.dy - 130 + (offsetIndex * 22),
        ),
        importType == AssetType.video
            ? (videoDimensions == null
                  ? const Size(520, 340)
                  : _windowSizeByFittingAspect(
                      currentSize: const Size(520, 340),
                      contentWidth: videoDimensions.width,
                      contentHeight: videoDimensions.height,
                    ))
            : (imageDimensions == null
                  ? const Size(420, 300)
                  : _windowSizeByFittingAspect(
                      currentSize: const Size(420, 300),
                      contentWidth: imageDimensions.width,
                      contentHeight: imageDimensions.height,
                    )),
      );

      nextWindows.add(
        AssetWindowState(
          asset: WorkspaceAsset(
            id: _newId('asset'),
            filename: importFilename,
            md5: digest,
            type: importType,
            colorValue: _colorFromDigest(digest),
            note: importType == AssetType.video
                ? 'Imported ${videoDurationMs != null && videoDurationMs < 120000 ? 'short video' : 'long video'} from ${file.parent.path.split(Platform.pathSeparator).last}.'
                : type == AssetType.video
                ? 'Converted single-frame video from ${file.parent.path.split(Platform.pathSeparator).last}.'
                : 'Imported image from ${file.parent.path.split(Platform.pathSeparator).last}.',
            videoDurationMs: videoDurationMs,
            filePath: importPath,
            fileBookmark: fileBookmark,
            intrinsicWidth: importType == AssetType.video ? videoDimensions?.width : imageDimensions?.width,
            intrinsicHeight: importType == AssetType.video ? videoDimensions?.height : imageDimensions?.height,
          ),
          position: basePlacement,
          size: importType == AssetType.video
              ? (videoDimensions == null
                    ? const Size(520, 340)
                    : _windowSizeByFittingAspect(
                        currentSize: const Size(520, 340),
                        contentWidth: videoDimensions.width,
                        contentHeight: videoDimensions.height,
                      ))
              : (imageDimensions == null
                    ? const Size(420, 300)
                    : _windowSizeByFittingAspect(
                        currentSize: const Size(420, 300),
                        contentWidth: imageDimensions.width,
                        contentHeight: imageDimensions.height,
                      )),
          zoom: 1,
          zIndex: nextZ,
        ),
      );
      existingAssetDigests.add(digest);

      offsetIndex = (offsetIndex + 1) % 8;
    }

    _updateSession(
      _session!.copyWith(
        workspaces: _workspaces
            .map((entry) => entry.id == workspace.id ? entry.copyWith(windows: nextWindows, isOpen: true) : entry)
            .toList(),
        knownFolders: _session!.knownFolders,
        folderPopularity: _session!.folderPopularity,
      ),
    );
    _queueThumbnailRefresh(workspace.id);
    if (skippedDuplicateCount > 0) {
      _showMessage(
        'Skipped $skippedDuplicateCount duplicate asset${skippedDuplicateCount == 1 ? '' : 's'} already in this workspace.',
      );
    }
  }
}
