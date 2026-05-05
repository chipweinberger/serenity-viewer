import Cocoa
import FlutterMacOS

private let relaunchWindowFrameDefaultsKey = "serenity.relaunchWindowFrame"

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let relaunchWindowFrame = UserDefaults.standard.string(forKey: relaunchWindowFrameDefaultsKey)
    let windowFrame = relaunchWindowFrame.map(NSRectFromString) ?? self.frame
    self.minSize = NSSize(width: 320, height: 240)
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    UserDefaults.standard.removeObject(forKey: relaunchWindowFrameDefaultsKey)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
