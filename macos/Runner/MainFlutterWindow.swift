import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Disable automatic window tabbing (hides "Show Tab Bar" / "Show All Tabs" menu items)
    NSWindow.allowsAutomaticWindowTabbing = false

    // Make title bar transparent so it blends with the Flutter background color
    self.titlebarAppearsTransparent = true

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
