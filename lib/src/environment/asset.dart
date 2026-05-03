import 'package:flutter/material.dart';

import 'package:serenity_viewer/src/foundation/app_constants.dart';

@immutable
class Asset {
  const Asset({
    required this.id,
    required this.filename,
    required this.md5,
    required this.type,
    required this.colorValue,
    required this.note,
    this.videoDurationMs,
    this.filePath,
    this.fileBookmark,
    this.intrinsicWidth,
    this.intrinsicHeight,
  });

  final String id;
  final String filename;
  final String md5;
  final AssetType type;
  final int colorValue;
  final String note;
  final int? videoDurationMs;
  final String? filePath;
  final String? fileBookmark;
  final double? intrinsicWidth;
  final double? intrinsicHeight;

  VideoLengthCategory? get videoLengthCategory {
    if (type != AssetType.video) {
      return null;
    }
    if (videoDurationMs == null) {
      return VideoLengthCategory.long;
    }
    return videoDurationMs! < 120000 ? VideoLengthCategory.short : VideoLengthCategory.long;
  }

  Color get color => assetColorFromMd5(md5, fallbackColorValue: colorValue);

  double get aspectRatio {
    if (intrinsicWidth != null && intrinsicHeight != null && intrinsicWidth! > 0 && intrinsicHeight! > 0) {
      return intrinsicWidth! / intrinsicHeight!;
    }
    return type == AssetType.video ? (16 / 9) : (4 / 3);
  }

  Asset copyWith({
    String? id,
    String? filename,
    String? md5,
    AssetType? type,
    int? colorValue,
    String? note,
    int? videoDurationMs,
    String? filePath,
    String? fileBookmark,
    double? intrinsicWidth,
    double? intrinsicHeight,
    bool clearFilePath = false,
  }) {
    return Asset(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      md5: md5 ?? this.md5,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      note: note ?? this.note,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      fileBookmark: clearFilePath ? null : (fileBookmark ?? this.fileBookmark),
      intrinsicWidth: intrinsicWidth ?? this.intrinsicWidth,
      intrinsicHeight: intrinsicHeight ?? this.intrinsicHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'md5': md5,
      'type': type.name,
      'colorValue': colorValue,
      'note': note,
      'videoDurationMs': videoDurationMs,
      'filePath': filePath,
      'fileBookmark': fileBookmark,
      'intrinsicWidth': intrinsicWidth,
      'intrinsicHeight': intrinsicHeight,
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      filename: json['filename'] as String,
      md5: json['md5'] as String,
      type: AssetType.values.byName(json['type'] as String),
      colorValue: json['colorValue'] as int,
      note: json['note'] as String? ?? '',
      videoDurationMs: json['videoDurationMs'] as int?,
      filePath: json['filePath'] as String?,
      fileBookmark: json['fileBookmark'] as String?,
      intrinsicWidth: (json['intrinsicWidth'] as num?)?.toDouble(),
      intrinsicHeight: (json['intrinsicHeight'] as num?)?.toDouble(),
    );
  }
}
