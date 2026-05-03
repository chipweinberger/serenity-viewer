// ignore_for_file: invalid_use_of_protected_member

part of 'package:serenity_viewer/src/app/app_shell.dart';

extension _AppShellMediaImportActions on _AppShellState {
  ImportCoordinator _buildImportCoordinator() {
    return ImportCoordinator(
      imageExtensions: _AppShellState._imageExtensions,
      videoExtensions: _AppShellState._videoExtensions,
      confirmSingleFrameConversion: _videoConversionCoordinator.confirmSingleFrameConversion,
      exportVideoFrameToJpeg: ({required sourcePath, required probe, positionMs}) {
        return _videoConversionCoordinator.exportVideoFrameToJpeg(
          sourcePath: sourcePath,
          probe: probe,
          positionMs: positionMs,
        );
      },
      createFileBookmark: _appShellPlatformBridge.createFileBookmark,
      md5ForFile: _mediaBridge.md5ForFile,
      imageDimensionsForFile: _mediaBridge.imageDimensionsForFile,
      videoDurationMsForFile: _mediaBridge.videoDurationMsForFile,
      probeVideoFile: _mediaBridge.probeVideoFile,
      newId: _newId,
      colorFromDigest: _colorFromDigest,
    );
  }

  Future<void> _pickAndImportAssets() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Media',
          extensions: [..._AppShellState._imageExtensions, ..._AppShellState._videoExtensions],
        ),
      ],
    );

    await _importFiles(files);
  }

  Future<void> _importFiles(List<XFile> files) async {
    if (files.isEmpty || _persistenceState.environment == null) {
      return;
    }

    final workspace = _activeWorkspace;
    final ImportResult result = await _buildImportCoordinator().importFiles(
      environment: _persistenceState.environment!,
      workspace: workspace,
      files: files,
    );

    if (!result.hadSupportedFiles) {
      _showMessage('No supported image or video files were found in that selection.');
      return;
    }

    if (result.importedCount > 0) {
      _updateEnvironment(result.environment);
      _queueThumbnailRefresh(workspace.id);
    }
    if (result.skippedDuplicateCount > 0) {
      _showMessage(
        'Skipped ${result.skippedDuplicateCount} duplicate asset'
        '${result.skippedDuplicateCount == 1 ? '' : 's'} already in this workspace.',
      );
    }
  }
}
