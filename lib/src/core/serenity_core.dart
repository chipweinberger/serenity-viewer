part of '../../main.dart';

const MethodChannel _bookmarkChannel = MethodChannel('serenity/file_bookmarks');
const MethodChannel _cursorChannel = MethodChannel('serenity/mouse_cursor');
const MethodChannel _fileActionsChannel = MethodChannel('serenity/file_actions');
const MethodChannel _preferencesChannel = MethodChannel('serenity/preferences');
const MethodChannel _videoToolsChannel = MethodChannel('serenity/video_tools');
const MethodChannel _windowChannel = MethodChannel('serenity/window');
const double _workspaceExtent = 4000;
const double _workspaceMinCoordinate = -_workspaceExtent;
const double _workspaceMaxCoordinate = _workspaceExtent;
const double _workspaceMinZoom = 0.32;
const double _workspaceMaxZoom = 4;
const Offset _defaultWorkspaceCenter = Offset.zero;

enum SerenityScreen { workspace, library }

enum WorkspaceLayoutMode { freeform, expose }

enum AssetType { image, video }

enum VideoLengthCategory { short, long }

enum WorkspaceSort { views, recentlyViewed, recentlyCreated, name }

const List<Color> _assetColorPalette = [
  Color(0xFFD5A37A),
  Color(0xFFC8907A),
  Color(0xFFD1B179),
  Color(0xFFB8C07A),
  Color(0xFF8FB38A),
  Color(0xFF78B3A7),
  Color(0xFF7EAFC4),
  Color(0xFF8EA0D1),
  Color(0xFFA891C8),
  Color(0xFFC191BC),
  Color(0xFFC88EA1),
  Color(0xFFB29A84),
];

Color _assetColorFromMd5(String md5, {int? fallbackColorValue}) {
  final normalized = md5.trim().toLowerCase();
  final safeDigest = normalized.length >= 8 ? normalized.substring(0, 8) : normalized;
  final paletteIndex = int.tryParse(safeDigest, radix: 16);
  if (paletteIndex == null) {
    if (fallbackColorValue != null) {
      return Color(fallbackColorValue);
    }
    return _assetColorPalette.first;
  }
  return _assetColorPalette[paletteIndex % _assetColorPalette.length];
}
