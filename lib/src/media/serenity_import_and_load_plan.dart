// ignore_for_file: invalid_use_of_protected_member

part of '../app/serenity_shell.dart';

extension _SerenityShellImportAndLoadPlan on _SerenityShellState {
  SerenityImportCoordinator _buildImportCoordinator() {
    return SerenityImportCoordinator(
      imageExtensions: _SerenityShellState._imageExtensions,
      videoExtensions: _SerenityShellState._videoExtensions,
      confirmSingleFrameConversion: _confirmSingleFrameConversion,
      exportVideoFrameToJpeg: ({required sourcePath, required probe, positionMs}) {
        return _exportVideoFrameToJpeg(sourcePath: sourcePath, probe: probe, positionMs: positionMs);
      },
      createFileBookmark: _createFileBookmark,
      md5ForFile: _md5ForFile,
      imageDimensionsForFile: _imageDimensionsForFile,
      videoDurationMsForFile: _videoDurationMsForFile,
      probeVideoFile: _probeVideoFile,
      newId: _newId,
      colorFromDigest: _colorFromDigest,
    );
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
    if (files.isEmpty || _persistenceState.session == null) {
      return;
    }

    final workspace = _activeWorkspace;
    final SerenityImportResult result = await _buildImportCoordinator().importFiles(
      session: _persistenceState.session!,
      workspace: workspace,
      files: files,
    );

    if (!result.hadSupportedFiles) {
      _showMessage('No supported image or video files were found in that selection.');
      return;
    }

    if (result.importedCount > 0) {
      _updateSession(result.session);
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
