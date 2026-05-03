import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';
import 'package:serenity_viewer/src/environment/window.dart';
import 'package:serenity_viewer/src/environment/link.dart';

Offset _workspaceViewportCenterForWindows(List<Window> windows) {
  if (windows.isEmpty) {
    return defaultWorkspaceCenter;
  }

  var minX = windows.first.position.dx;
  var minY = windows.first.position.dy;
  var maxX = windows.first.position.dx + windows.first.size.width;
  var maxY = windows.first.position.dy + windows.first.size.height;
  for (final window in windows.skip(1)) {
    minX = math.min(minX, window.position.dx);
    minY = math.min(minY, window.position.dy);
    maxX = math.max(maxX, window.position.dx + window.size.width);
    maxY = math.max(maxY, window.position.dy + window.size.height);
  }

  return Offset(
    ((minX + maxX) / 2).clamp(workspaceMinCoordinate, workspaceMaxCoordinate),
    ((minY + maxY) / 2).clamp(workspaceMinCoordinate, workspaceMaxCoordinate),
  );
}

@immutable
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastViewedAt,
    required this.views,
    required this.links,
    required this.windows,
    required this.isOpen,
    required this.viewportCenterDx,
    required this.viewportCenterDy,
    required this.viewportZoom,
    this.thumbnailPath,
    this.thumbnailVersion = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastViewedAt;
  final int views;
  final List<Link> links;
  final List<Window> windows;
  final bool isOpen;
  final double viewportCenterDx;
  final double viewportCenterDy;
  final double viewportZoom;
  final String? thumbnailPath;
  final int thumbnailVersion;

  Offset get viewportCenter => Offset(viewportCenterDx, viewportCenterDy);

  Workspace copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastViewedAt,
    int? views,
    List<Link>? links,
    List<Window>? windows,
    bool? isOpen,
    double? viewportCenterDx,
    double? viewportCenterDy,
    double? viewportZoom,
    String? thumbnailPath,
    int? thumbnailVersion,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      views: views ?? this.views,
      links: links ?? this.links,
      windows: windows ?? this.windows,
      isOpen: isOpen ?? this.isOpen,
      viewportCenterDx: viewportCenterDx ?? this.viewportCenterDx,
      viewportCenterDy: viewportCenterDy ?? this.viewportCenterDy,
      viewportZoom: viewportZoom ?? this.viewportZoom,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailVersion: thumbnailVersion ?? this.thumbnailVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastViewedAt': lastViewedAt.toIso8601String(),
      'views': views,
      'links': links.map((link) => link.toJson()).toList(),
      'windows': windows.map((window) => window.toJson()).toList(),
      'isOpen': isOpen,
      'viewportCenterDx': viewportCenterDx,
      'viewportCenterDy': viewportCenterDy,
      'viewportZoom': viewportZoom,
      'thumbnailPath': thumbnailPath,
      'thumbnailVersion': thumbnailVersion,
    };
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final links = (json['links'] as List<dynamic>? ?? const [])
        .map((entry) => Link.fromJson(entry as Map<String, dynamic>))
        .toList();
    final windows = (json['windows'] as List<dynamic>)
        .map((entry) => Window.fromJson(entry as Map<String, dynamic>))
        .toList();
    final fallbackCenter = _workspaceViewportCenterForWindows(windows);
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastViewedAt: DateTime.parse(json['lastViewedAt'] as String),
      views: json['views'] as int? ?? 0,
      links: links,
      windows: windows,
      isOpen: json['isOpen'] as bool,
      viewportCenterDx: (json['viewportCenterDx'] as num?)?.toDouble() ?? fallbackCenter.dx,
      viewportCenterDy: (json['viewportCenterDy'] as num?)?.toDouble() ?? fallbackCenter.dy,
      viewportZoom: (json['viewportZoom'] as num?)?.toDouble() ?? 1,
      thumbnailPath: json['thumbnailPath'] as String?,
      thumbnailVersion: json['thumbnailVersion'] as int? ?? 0,
    );
  }
}
