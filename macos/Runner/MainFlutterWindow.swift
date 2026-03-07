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

    // Set dark background immediately so there is no white flash before Flutter paints.
    // Matches the default classicDark theme background (#1E1F22).
    // Flutter will update this to the saved theme colour once it loads.
    self.backgroundColor = NSColor(red: 0.118, green: 0.122, blue: 0.133, alpha: 1.0)

    // Attach an empty toolbar so the traffic-light button bar remains visible
    // in full-screen mode instead of auto-hiding with the menu bar.
    let toolbar = NSToolbar(identifier: "MainToolbar")
    toolbar.showsBaselineSeparator = false
    self.toolbar = toolbar
    if #available(macOS 11.0, *) {
      self.toolbarStyle = .unified
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
