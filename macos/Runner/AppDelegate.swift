import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  private var recentProjects: [[String: String]] = []

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Enforce single instance in release builds only.
    // Debug builds skip this so `flutter run` can relaunch the app freely.
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
      .filter { $0 != NSRunningApplication.current }
    if !others.isEmpty {
      others.first?.activate(options: .activateIgnoringOtherApps)
      let alert = NSAlert()
      alert.messageText = "DAW Project Manager is already running"
      alert.informativeText = "Please close the existing instance before opening a new one."
      alert.alertStyle = .informational
      alert.addButton(withTitle: "OK")
      alert.runModal()
      exit(0)
    }
  }

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
    #if DEBUG
    return true  // quit on window close in debug so flutter run always gets a fresh process
    #else
    return false
    #endif
  }

  // Re-show the window when the user clicks the Dock icon after closing it.
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      sender.windows.first?.makeKeyAndOrderFront(nil)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
