import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  private var recentProjects: [[String: String]] = []

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard let window = NSApplication.shared.windows.first,
          let vc = window.contentViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: "com.bandpassrecords.dpm/dock_menu",
      binaryMessenger: vc.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setRecentProjects",
         let args = call.arguments as? [[String: String]] {
        self?.recentProjects = args
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Builds the right-click Dock menu showing the five most-recently-modified projects.
  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    guard !recentProjects.isEmpty else { return nil }
    let menu = NSMenu()
    for project in recentProjects {
      guard let name = project["name"], let path = project["path"] else { continue }
      let item = NSMenuItem(
        title: name,
        action: #selector(openRecentProject(_:)),
        keyEquivalent: ""
      )
      item.representedObject = path
      item.target = self
      menu.addItem(item)
    }
    return menu
  }

  @objc private func openRecentProject(_ sender: NSMenuItem) {
    guard let path = sender.representedObject as? String else { return }
    NSWorkspace.shared.open(URL(fileURLWithPath: path))
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
