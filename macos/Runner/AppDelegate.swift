import Cocoa
import AVFoundation
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var activeSecurityScopedUrls: [URL] = []

  override func applicationDidFinishLaunching(_ notification: Notification) {
    if #available(macOS 10.12, *) {
      NSWindow.allowsAutomaticWindowTabbing = false
    }

    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      super.applicationDidFinishLaunching(notification)
      return
    }
    let bookmarkChannel = FlutterMethodChannel(
      name: "serenity/file_bookmarks",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let cursorChannel = FlutterMethodChannel(
      name: "serenity/mouse_cursor",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let fileActionsChannel = FlutterMethodChannel(
      name: "serenity/file_actions",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let videoToolsChannel = FlutterMethodChannel(
      name: "serenity/video_tools",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let preferencesChannel = FlutterMethodChannel(
      name: "serenity/preferences",
      binaryMessenger: controller.engine.binaryMessenger
    )
    let windowChannel = FlutterMethodChannel(
      name: "serenity/window",
      binaryMessenger: controller.engine.binaryMessenger
    )

    bookmarkChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "createBookmark":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(nil)
          return
        }
        result(self.createBookmark(for: path))
      case "resolveBookmark":
        guard
          let args = call.arguments as? [String: Any],
          let bookmark = args["bookmark"] as? String
        else {
          result(nil)
          return
        }
        result(self.resolveBookmark(bookmark))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    cursorChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      guard call.method == "setCursor" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let args = call.arguments as? [String: Any]
      let kind = args?["kind"] as? String ?? "basic"
      self.setCursor(kind: kind)
      result(nil)
    }

    fileActionsChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      guard call.method == "revealInFinder" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(nil)
        return
      }

      result(self.revealInFinder(path: path))
    }

    videoToolsChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      switch call.method {
      case "probeVideo":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(nil)
          return
        }
        result(self.probeVideo(path: path))
      case "exportVideoFrameToJpeg":
        guard
          let args = call.arguments as? [String: Any],
          let sourcePath = args["sourcePath"] as? String,
          let destinationPath = args["destinationPath"] as? String
        else {
          result(nil)
          return
        }

        let positionMs = args["positionMs"] as? Int ?? 0
        let normalizedCrop = args["normalizedCrop"] as? [String: Any]
        result(
          self.exportVideoFrameToJpeg(
            sourcePath: sourcePath,
            destinationPath: destinationPath,
            positionMs: positionMs,
            normalizedCrop: normalizedCrop
          )
        )
      case "renderVideoThumbnail":
        guard
          let args = call.arguments as? [String: Any],
          let sourcePath = args["sourcePath"] as? String
        else {
          result(nil)
          return
        }

        let positionMs = args["positionMs"] as? Int ?? 0
        let targetWidth = args["targetWidth"] as? Int
        let normalizedCrop = args["normalizedCrop"] as? [String: Any]
        result(
          self.renderVideoThumbnail(
            sourcePath: sourcePath,
            positionMs: positionMs,
            targetWidth: targetWidth,
            normalizedCrop: normalizedCrop
          )
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    preferencesChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getLastEnvironmentPath":
        result(UserDefaults.standard.string(forKey: "lastEnvironmentPath"))
      case "setLastEnvironmentPath":
        let args = call.arguments as? [String: Any]
        let path = args?["path"] as? String
        UserDefaults.standard.set(path, forKey: "lastEnvironmentPath")
        result(nil)
      case "clearLastEnvironmentPath":
        UserDefaults.standard.removeObject(forKey: "lastEnvironmentPath")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }

      guard call.method == "setWindowTitle" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let args = call.arguments as? [String: Any]
      let title = args?["title"] as? String ?? "Serenity"
      self.mainFlutterWindow?.title = title
      result(nil)
    }

    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func createBookmark(for path: String) -> String? {
    let fileUrl = URL(fileURLWithPath: path)

    do {
      let bookmarkData = try fileUrl.bookmarkData(
        options: [.withSecurityScope],
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return bookmarkData.base64EncodedString()
    } catch {
      return nil
    }
  }

  private func resolveBookmark(_ base64: String) -> String? {
    guard let bookmarkData = Data(base64Encoded: base64) else {
      return nil
    }

    do {
      var isStale = false
      let fileUrl = try URL(
        resolvingBookmarkData: bookmarkData,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      if fileUrl.startAccessingSecurityScopedResource() {
        activeSecurityScopedUrls.append(fileUrl)
      }

      return fileUrl.path
    } catch {
      return nil
    }
  }

  private func setCursor(kind: String) {
    let cursor: NSCursor
    switch kind {
    case "leftRight":
      cursor = .resizeLeftRight
    case "upDown":
      cursor = .resizeUpDown
    case "diagonalPrimary":
      cursor = diagonalCursor(systemSymbolName: "arrow.up.left.and.arrow.down.right", fallback: .crosshair)
    case "diagonalSecondary":
      cursor = diagonalCursor(systemSymbolName: "arrow.up.right.and.arrow.down.left", fallback: .crosshair)
    default:
      cursor = .arrow
    }

    cursor.set()
  }

  private func diagonalCursor(systemSymbolName: String, fallback: NSCursor) -> NSCursor {
    guard #available(macOS 11.0, *) else {
      return fallback
    }

    let imageSize = NSSize(width: 18, height: 18)
    guard let symbol = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil) else {
      return fallback
    }

    let configured = symbol.withSymbolConfiguration(
      NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    ) ?? symbol

    let image = NSImage(size: imageSize)
    image.lockFocus()
    configured.draw(in: NSRect(origin: .zero, size: imageSize))
    image.unlockFocus()
    image.isTemplate = true
    return NSCursor(image: image, hotSpot: NSPoint(x: imageSize.width / 2, y: imageSize.height / 2))
  }

  private func copyFileDates(sourcePath: String, destinationPath: String) -> Bool {
    let sourceUrl = URL(fileURLWithPath: sourcePath)
    let destinationUrl = URL(fileURLWithPath: destinationPath)

    do {
      let sourceValues = try sourceUrl.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
      var destinationValues = URLResourceValues()
      destinationValues.creationDate = sourceValues.creationDate
      destinationValues.contentModificationDate = sourceValues.contentModificationDate
      var mutableDestinationUrl = destinationUrl
      try mutableDestinationUrl.setResourceValues(destinationValues)
      return true
    } catch {
      return false
    }
  }

  private func revealInFinder(path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return false
    }

    NSWorkspace.shared.activateFileViewerSelecting([url])
    return true
  }

  private func probeVideo(path: String) -> [String: Any]? {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return nil
    }

    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .video).first else {
      return nil
    }

    let transformedSize = track.naturalSize.applying(track.preferredTransform)
    let width = Int(abs(transformedSize.width).rounded())
    let height = Int(abs(transformedSize.height).rounded())
    let durationSeconds = CMTimeGetSeconds(asset.duration)
    let durationMs = durationSeconds.isFinite ? Int((durationSeconds * 1000).rounded()) : nil

    var frameCount: Int? = nil
    let minFrameDurationSeconds = CMTimeGetSeconds(track.minFrameDuration)
    if minFrameDurationSeconds.isFinite && minFrameDurationSeconds > 0 && durationSeconds.isFinite && durationSeconds > 0 {
      frameCount = max(1, Int((durationSeconds / minFrameDurationSeconds).rounded()))
    } else if track.nominalFrameRate > 0 && durationSeconds.isFinite && durationSeconds > 0 {
      frameCount = max(1, Int((durationSeconds * Double(track.nominalFrameRate)).rounded()))
    }

    return [
      "durationMs": durationMs as Any,
      "width": width,
      "height": height,
      "frameCount": frameCount as Any,
    ]
  }

  private func exportVideoFrameToJpeg(
    sourcePath: String,
    destinationPath: String,
    positionMs: Int,
    normalizedCrop: [String: Any]?
  ) -> [String: Any]? {
    let sourceUrl = URL(fileURLWithPath: sourcePath)
    let destinationUrl = URL(fileURLWithPath: destinationPath)
    guard FileManager.default.fileExists(atPath: sourceUrl.path) else {
      return nil
    }

    let asset = AVURLAsset(url: sourceUrl)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero

    let time = CMTime(value: CMTimeValue(max(0, positionMs)), timescale: 1000)

    do {
      let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
      let cropRect = cropRectForImage(cgImage, normalizedCrop: normalizedCrop)
      let outputImage = cgImage.cropping(to: cropRect) ?? cgImage

      let bitmap = NSBitmapImageRep(cgImage: outputImage)
      guard let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else {
        return nil
      }

      try jpegData.write(to: destinationUrl, options: .atomic)
      _ = copyFileDates(sourcePath: sourcePath, destinationPath: destinationPath)

      return [
        "path": destinationPath,
        "filename": destinationUrl.lastPathComponent,
        "width": outputImage.width,
        "height": outputImage.height,
      ]
    } catch {
      return nil
    }
  }

  private func renderVideoThumbnail(
    sourcePath: String,
    positionMs: Int,
    targetWidth: Int?,
    normalizedCrop: [String: Any]?
  ) -> FlutterStandardTypedData? {
    let sourceUrl = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceUrl.path) else {
      return nil
    }

    let asset = AVURLAsset(url: sourceUrl)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    imageGenerator.requestedTimeToleranceBefore = .zero
    imageGenerator.requestedTimeToleranceAfter = .zero

    if let targetWidth, targetWidth > 0 {
      imageGenerator.maximumSize = CGSize(width: targetWidth, height: targetWidth * 2)
    }

    let time = CMTime(value: CMTimeValue(max(0, positionMs)), timescale: 1000)

    do {
      let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
      let cropRect = cropRectForImage(cgImage, normalizedCrop: normalizedCrop)
      let outputImage = cgImage.cropping(to: cropRect) ?? cgImage

      let bitmap = NSBitmapImageRep(cgImage: outputImage)
      guard let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.88]) else {
        return nil
      }

      return FlutterStandardTypedData(bytes: jpegData)
    } catch {
      return nil
    }
  }

  private func cropRectForImage(_ image: CGImage, normalizedCrop: [String: Any]?) -> CGRect {
    let imageRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
    guard let normalizedCrop else {
      return imageRect
    }

    let left = (normalizedCrop["left"] as? Double ?? 0).clamped(to: 0...1)
    let top = (normalizedCrop["top"] as? Double ?? 0).clamped(to: 0...1)
    let width = (normalizedCrop["width"] as? Double ?? 1).clamped(to: 0...1)
    let height = (normalizedCrop["height"] as? Double ?? 1).clamped(to: 0...1)

    let cropX = CGFloat(left) * CGFloat(image.width)
    let cropY = CGFloat(top) * CGFloat(image.height)
    let cropWidth = max(1, min(CGFloat(width) * CGFloat(image.width), CGFloat(image.width) - cropX))
    let cropHeight = max(1, min(CGFloat(height) * CGFloat(image.height), CGFloat(image.height) - cropY))

    return CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight).intersection(imageRect)
  }
}

private extension Double {
  func clamped(to range: ClosedRange<Double>) -> Double {
    min(max(self, range.lowerBound), range.upperBound)
  }
}
