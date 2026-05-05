import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/asset.dart';
import 'package:serenity_viewer/src/environment/environment.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/workspace.dart';
import 'package:serenity_viewer/src/foundation/app_constants.dart';

Environment buildSeedEnvironment() {
  return _SeedEnvironmentBuilder(DateTime.now()).build();
}

class _SeedEnvironmentBuilder {
  _SeedEnvironmentBuilder(this.now);

  final DateTime now;

  Environment build() {
    return Environment(
      activeWorkspaceId: 'ws-story',
      knownFolders: const [],
      folderPopularity: const {},
      autoLoadVideos: false,
      imageLoadLimit: 300,
      shortVideoLoadLimit: 36,
      longVideoLoadLimit: 12,
      workspaces: [_buildStoryWorkspace(), _buildCutWorkspace(), _buildArchiveWorkspace()],
    );
  }

  Workspace _buildStoryWorkspace() {
    return Workspace(
      id: 'ws-story',
      name: 'Story Moodboard',
      createdAt: now.subtract(const Duration(days: 6)),
      lastViewedAt: now.subtract(const Duration(minutes: 4)),
      views: 0,
      links: const [],
      isOpen: true,
      viewportCenterDx: defaultWorkspaceCenter.dx,
      viewportCenterDy: defaultWorkspaceCenter.dy,
      viewportZoom: 1,
      windows: [
        _buildWindow(
          id: 'asset-hero',
          filename: 'hero-shot.jpg',
          md5: '90ab26ecf6a13c1d2af43d98b1d398d4',
          type: AssetType.image,
          position: const Offset(-192, -72),
          size: const Size(360, 260),
          zIndex: 1,
          colorValue: const Color(0xFFD8A67A).toARGB32(),
          note: 'Warm key art reference with gentle contrast.',
          intrinsicWidth: 1600,
          intrinsicHeight: 1200,
        ),
        _buildWindow(
          id: 'asset-bts',
          filename: 'behind-the-scenes.mp4',
          md5: '7dd9f09757f4b39b6d28f1f2df88ce30',
          type: AssetType.video,
          position: const Offset(88, -122),
          size: const Size(390, 280),
          zIndex: 2,
          colorValue: const Color(0xFF95A8C9).toARGB32(),
          note: 'Muted by default. Useful for motion pacing and camera feel.',
          videoDurationMs: 84000,
          intrinsicWidth: 1920,
          intrinsicHeight: 1080,
        ),
        _buildWindow(
          id: 'asset-details',
          filename: 'fabric-details.png',
          md5: '1914f0d15c4cc88932adf0ccf9db9f4d',
          type: AssetType.image,
          position: const Offset(198, 48),
          size: const Size(290, 230),
          zIndex: 3,
          colorValue: const Color(0xFFC9B896).toARGB32(),
          note: 'Texture reference pinned over the larger pieces.',
          intrinsicWidth: 1400,
          intrinsicHeight: 1050,
        ),
      ],
    );
  }

  Workspace _buildCutWorkspace() {
    return Workspace(
      id: 'ws-cut',
      name: 'Cut Review',
      createdAt: now.subtract(const Duration(days: 2)),
      lastViewedAt: now.subtract(const Duration(hours: 2)),
      views: 0,
      links: const [],
      isOpen: true,
      viewportCenterDx: defaultWorkspaceCenter.dx,
      viewportCenterDy: defaultWorkspaceCenter.dy,
      viewportZoom: 1,
      windows: [
        _buildWindow(
          id: 'asset-cut-1',
          filename: 'sequence-a.mov',
          md5: '49a4ed9f6b7eb8f4e4bb8c7dc55cf87d',
          type: AssetType.video,
          position: const Offset(-162, -102),
          size: const Size(420, 290),
          zIndex: 2,
          colorValue: const Color(0xFF8DB8A6).toARGB32(),
          note: 'Review cut with dialogue muted by default.',
          videoDurationMs: 310000,
          intrinsicWidth: 1920,
          intrinsicHeight: 1080,
        ),
        _buildWindow(
          id: 'asset-cut-2',
          filename: 'continuity-board.jpg',
          md5: '8cf4356f1e8af0952af14d8b3fd7dc88',
          type: AssetType.image,
          position: const Offset(218, -12),
          size: const Size(280, 220),
          zIndex: 3,
          colorValue: const Color(0xFFDCC97D).toARGB32(),
          note: 'Shot order and timing notes parked next to the cut.',
          intrinsicWidth: 1600,
          intrinsicHeight: 1200,
        ),
      ],
    );
  }

  Workspace _buildArchiveWorkspace() {
    return Workspace(
      id: 'ws-archive',
      name: 'Archive Pulls',
      createdAt: now.subtract(const Duration(days: 15)),
      lastViewedAt: now.subtract(const Duration(days: 3)),
      views: 0,
      links: const [],
      isOpen: false,
      viewportCenterDx: defaultWorkspaceCenter.dx,
      viewportCenterDy: defaultWorkspaceCenter.dy,
      viewportZoom: 1,
      windows: const [],
    );
  }

  Window _buildWindow({
    required String id,
    required String filename,
    required String md5,
    required AssetType type,
    required Offset position,
    required Size size,
    required int zIndex,
    required int colorValue,
    required String note,
    int? videoDurationMs,
    double? intrinsicWidth,
    double? intrinsicHeight,
  }) {
    return Window(
      asset: Asset(
        id: id,
        filename: filename,
        md5: md5,
        type: type,
        colorValue: colorValue,
        note: note,
        videoDurationMs: videoDurationMs,
        intrinsicWidth: intrinsicWidth,
        intrinsicHeight: intrinsicHeight,
      ),
      position: position,
      size: size,
      zoom: 1,
      zIndex: zIndex,
    );
  }
}
