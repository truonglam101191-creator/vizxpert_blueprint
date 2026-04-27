import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Minimum size for DAW-style layout
    self.minSize = NSSize(width: 1200, height: 800)

    // Set a comfortable initial size
    if let screen = self.screen {
      let screenRect = screen.visibleFrame
      let width: CGFloat = min(1440, screenRect.width * 0.85)
      let height: CGFloat = min(900, screenRect.height * 0.85)
      let x = screenRect.origin.x + (screenRect.width - width) / 2
      let y = screenRect.origin.y + (screenRect.height - height) / 2
      self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
