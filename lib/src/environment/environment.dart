import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/environment/workspace.dart';

@immutable
class Environment {
  const Environment({
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.knownFolders,
    required this.folderPopularity,
    required this.autoLoadVideos,
    required this.imageLoadLimit,
    required this.shortVideoLoadLimit,
    required this.longVideoLoadLimit,
  });

  final List<Workspace> workspaces;
  final String activeWorkspaceId;
  final List<String> knownFolders;
  final Map<String, int> folderPopularity;
  final bool autoLoadVideos;
  final int imageLoadLimit;
  final int shortVideoLoadLimit;
  final int longVideoLoadLimit;

  Environment copyWith({
    List<Workspace>? workspaces,
    String? activeWorkspaceId,
    List<String>? knownFolders,
    Map<String, int>? folderPopularity,
    bool? autoLoadVideos,
    int? imageLoadLimit,
    int? shortVideoLoadLimit,
    int? longVideoLoadLimit,
  }) {
    return Environment(
      workspaces: workspaces ?? this.workspaces,
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      knownFolders: knownFolders ?? this.knownFolders,
      folderPopularity: folderPopularity ?? this.folderPopularity,
      autoLoadVideos: autoLoadVideos ?? this.autoLoadVideos,
      imageLoadLimit: imageLoadLimit ?? this.imageLoadLimit,
      shortVideoLoadLimit: shortVideoLoadLimit ?? this.shortVideoLoadLimit,
      longVideoLoadLimit: longVideoLoadLimit ?? this.longVideoLoadLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workspaces': workspaces.map((workspace) => workspace.toJson()).toList(),
      'activeWorkspaceId': activeWorkspaceId,
      'knownFolders': knownFolders,
      'folderPopularity': folderPopularity,
      'autoLoadVideos': autoLoadVideos,
      'imageLoadLimit': imageLoadLimit,
      'shortVideoLoadLimit': shortVideoLoadLimit,
      'longVideoLoadLimit': longVideoLoadLimit,
    };
  }

  Map<String, dynamic> toManifestJson() {
    return {
      'workspaceIds': workspaces.map((workspace) => workspace.id).toList(),
      'activeWorkspaceId': activeWorkspaceId,
      'knownFolders': knownFolders,
      'folderPopularity': folderPopularity,
      'autoLoadVideos': autoLoadVideos,
      'imageLoadLimit': imageLoadLimit,
      'shortVideoLoadLimit': shortVideoLoadLimit,
      'longVideoLoadLimit': longVideoLoadLimit,
    };
  }

  factory Environment.fromJson(Map<String, dynamic> json) {
    return Environment(
      workspaces: (json['workspaces'] as List<dynamic>)
          .map((entry) => Workspace.fromJson(entry as Map<String, dynamic>))
          .toList(),
      activeWorkspaceId: json['activeWorkspaceId'] as String,
      knownFolders: (json['knownFolders'] as List<dynamic>? ?? const []).cast<String>(),
      folderPopularity: (json['folderPopularity'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, value as int),
      ),
      autoLoadVideos: json['autoLoadVideos'] as bool? ?? false,
      imageLoadLimit: json['imageLoadLimit'] as int? ?? 300,
      shortVideoLoadLimit: json['shortVideoLoadLimit'] as int? ?? 36,
      longVideoLoadLimit: json['longVideoLoadLimit'] as int? ?? 12,
    );
  }

  factory Environment.fromManifestJson(Map<String, dynamic> json, List<Workspace> workspaces) {
    return Environment(
      workspaces: workspaces,
      activeWorkspaceId: json['activeWorkspaceId'] as String,
      knownFolders: (json['knownFolders'] as List<dynamic>? ?? const []).cast<String>(),
      folderPopularity: (json['folderPopularity'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, value as int),
      ),
      autoLoadVideos: json['autoLoadVideos'] as bool? ?? false,
      imageLoadLimit: json['imageLoadLimit'] as int? ?? 300,
      shortVideoLoadLimit: json['shortVideoLoadLimit'] as int? ?? 36,
      longVideoLoadLimit: json['longVideoLoadLimit'] as int? ?? 12,
    );
  }
}
