import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  private var recentProjects: [[String: String]] = []

  // Cross-process signal telling an already-running instance to surface its
  // window — needed because a second launch attempt (Dock/Finder icon) is a
  // separate process and can't just call windowManager.show() directly.
  private static let showWindowNotificationName = Notification.Name("com.bandpassrecords.dpm.showWindow")

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Enforce single instance in release builds only.
    // Debug builds skip this so `flutter run` can relaunch the app freely.
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
      .filter { $0 != NSRunningApplication.current }
    if !others.isEmpty {
      // Ask the running instance to show itself (it may be hidden in the
      // tray) instead of just telling the user to go close it manually.
      DistributedNotificationCenter.default().postNotificationName(
        AppDelegate.showWindowNotificationName, object: bundleId, userInfo: nil, deliverImmediately: true)
      others.first?.activate(options: .activateIgnoringOtherApps)
      exit(0)
    }

    DistributedNotificationCenter.default().addObserver(
      self,
      selector: #selector(handleShowWindowRequest),
      name: AppDelegate.showWindowNotificationName,
      object: nil
    )
  }

  @objc private func handleShowWindowRequest() {
    DispatchQueue.main.async {
      NSApp.activate()
      NSApplication.shared.windows.first?.makeKeyAndOrderFront(nil)
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
