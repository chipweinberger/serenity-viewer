import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/models/workspace_asset.dart';

@immutable
class AssetWindowState {
  const AssetWindowState({
    required this.asset,
    required this.position,
    required this.size,
    required this.zoom,
    this.videoPositionMs,
    this.videoPlaybackSpeed = 1.0,
    this.zoomBaseWidth,
    this.zoomBaseHeight,
    this.contentOffsetDx,
    this.contentOffsetDy,
    required this.zIndex,
  });

  final WorkspaceAsset asset;
  final Offset position;
  final Size size;
  final double zoom;
  final int? videoPositionMs;
  final double videoPlaybackSpeed;
  final double? zoomBaseWidth;
  final double? zoomBaseHeight;
  final double? contentOffsetDx;
  final double? contentOffsetDy;
  final int zIndex;

  Size? get zoomBaseSize {
    if (zoomBaseWidth == null || zoomBaseHeight == null) {
      return null;
    }
    return Size(zoomBaseWidth!, zoomBaseHeight!);
  }

  Offset get contentOffset => Offset(contentOffsetDx ?? 0, contentOffsetDy ?? 0);

  AssetWindowState copyWith({
    WorkspaceAsset? asset,
    Offset? position,
    Size? size,
    double? zoom,
    int? videoPositionMs,
    double? videoPlaybackSpeed,
    double? zoomBaseWidth,
    double? zoomBaseHeight,
    double? contentOffsetDx,
    double? contentOffsetDy,
    bool clearZoomBase = false,
    bool clearContentOffset = false,
    int? zIndex,
  }) {
    return AssetWindowState(
      asset: asset ?? this.asset,
      position: position ?? this.position,
      size: size ?? this.size,
      zoom: zoom ?? this.zoom,
      videoPositionMs: videoPositionMs ?? this.videoPositionMs,
      videoPlaybackSpeed: videoPlaybackSpeed ?? this.videoPlaybackSpeed,
      zoomBaseWidth: clearZoomBase ? null : (zoomBaseWidth ?? this.zoomBaseWidth),
      zoomBaseHeight: clearZoomBase ? null : (zoomBaseHeight ?? this.zoomBaseHeight),
      contentOffsetDx: clearContentOffset ? 0 : (contentOffsetDx ?? this.contentOffsetDx),
      contentOffsetDy: clearContentOffset ? 0 : (contentOffsetDy ?? this.contentOffsetDy),
      zIndex: zIndex ?? this.zIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset': asset.toJson(),
      'positionDx': position.dx,
      'positionDy': position.dy,
      'width': size.width,
      'height': size.height,
      'zoom': zoom,
      'videoPositionMs': videoPositionMs,
      'videoPlaybackSpeed': videoPlaybackSpeed,
      'zoomBaseWidth': zoomBaseWidth,
      'zoomBaseHeight': zoomBaseHeight,
      'contentOffsetDx': contentOffsetDx,
      'contentOffsetDy': contentOffsetDy,
      'zIndex': zIndex,
    };
  }

  factory AssetWindowState.fromJson(Map<String, dynamic> json) {
    return AssetWindowState(
      asset: WorkspaceAsset.fromJson(json['asset'] as Map<String, dynamic>),
      position: Offset((json['positionDx'] as num).toDouble(), (json['positionDy'] as num).toDouble()),
      size: Size((json['width'] as num).toDouble(), (json['height'] as num).toDouble()),
      zoom: (json['zoom'] as num).toDouble(),
      videoPositionMs: json['videoPositionMs'] as int?,
      videoPlaybackSpeed: (json['videoPlaybackSpeed'] as num?)?.toDouble() ?? 1.0,
      zoomBaseWidth: (json['zoomBaseWidth'] as num?)?.toDouble(),
      zoomBaseHeight: (json['zoomBaseHeight'] as num?)?.toDouble(),
      contentOffsetDx: (json['contentOffsetDx'] as num?)?.toDouble(),
      contentOffsetDy: (json['contentOffsetDy'] as num?)?.toDouble(),
      zIndex: json['zIndex'] as int,
    );
  }
}
