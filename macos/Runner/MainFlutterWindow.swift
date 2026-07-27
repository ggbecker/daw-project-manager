import Cocoa
import FlutterMacOS
import ServiceManagement

/// Native half of the `launch_at_startup` package on macOS.
///
/// That package is pure Dart: its Windows (registry) and Linux (.desktop)
/// backends work on their own, but its macOS backend only talks over the
/// `launch_at_startup` method channel and expects the host app to answer.
/// Rather than pull in the LaunchAtLogin Swift package it documents, this
/// answers the channel directly:
///
/// - macOS 13+: `SMAppService.mainApp`, the supported API — the app shows up
///   in System Settings → General → Login Items, where the user can revoke
///   it (which is why the Dart side re-reads this state on every launch).
/// - macOS 10.15–12: a `~/Library/LaunchAgents/<bundle-id>.plist` with
///   `RunAtLoad`, since `SMAppService` doesn't exist there and the older
///   `SMLoginItemSetEnabled` needs a separate bundled helper app.
///
/// The "start minimized" option forces the LaunchAgent mechanism on *every*
/// macOS version: the flag has to reach the app as a launch argument, and
/// `SMAppService.mainApp` gives no way to supply one — it just launches the
/// bundle. The plist can, via `open --args`. Only one mechanism is ever left
/// registered; switching between them tears the other one down.
enum LaunchAtStartupHandler {
  private static let channelName = "launch_at_startup"
  private static let minimizedDefaultsKey = "launchAtStartupMinimized"
  private static let minimizedFlag = "--minimized"

  static func register(with registrar: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(isEnabled())
      case "launchAtStartupSetEnabled":
        let args = call.arguments as? [String: Any]
        let value = args?["setEnabledValue"] as? Bool ?? false
        result(setEnabled(value))
      case "launchAtStartupSetLaunchMinimized":
        // Sent by AutoStartService.setup() before any enable(), because
        // launch_at_startup's macOS backend drops its own `args` parameter.
        // Persisted so a later isEnabled()/setEnabled() in a fresh process
        // still knows which mechanism this install is using.
        let args = call.arguments as? [String: Any]
        let value = args?["minimized"] as? Bool ?? false
        UserDefaults.standard.set(value, forKey: minimizedDefaultsKey)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var wantsMinimized: Bool {
    UserDefaults.standard.bool(forKey: minimizedDefaultsKey)
  }

  private static var bundleIdentifier: String {
    Bundle.main.bundleIdentifier ?? "io.bandpassrecords.dawProjectManager"
  }

  private static var legacyAgentURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents")
      .appendingPathComponent("\(bundleIdentifier).plist")
  }

  /// True if *either* mechanism is registered — the Dart side only wants to
  /// know whether the app launches at login, not how.
  private static func isEnabled() -> Bool {
    if FileManager.default.fileExists(atPath: legacyAgentURL.path) {
      return true
    }
    if #available(macOS 13.0, *) {
      return SMAppService.mainApp.status == .enabled
    }
    return false
  }

  private static func setEnabled(_ enabled: Bool) -> Bool {
    guard enabled else {
      // Tear down both, so a mechanism switch can't strand a registration.
      let agentOK = setLegacyAgentEnabled(false)
      let serviceOK = setModernServiceEnabled(false)
      return agentOK && serviceOK
    }

    // SMAppService can't pass a launch argument, so the minimized flag forces
    // the LaunchAgent path even on macOS 13+.
    if wantsMinimized {
      guard setLegacyAgentEnabled(true) else { return false }
      _ = setModernServiceEnabled(false)
      return true
    }

    if #available(macOS 13.0, *) {
      guard setModernServiceEnabled(true) else { return false }
      _ = setLegacyAgentEnabled(false)
      return true
    }
    return setLegacyAgentEnabled(true)
  }

  private static func setModernServiceEnabled(_ enabled: Bool) -> Bool {
    guard #available(macOS 13.0, *) else { return true }
    do {
      if enabled {
        // Re-registering an already-enabled app throws; treat that as success.
        if SMAppService.mainApp.status != .enabled {
          try SMAppService.mainApp.register()
        }
      } else if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      }
      return true
    } catch {
      NSLog("[LaunchAtStartup] SMAppService failed: \(error.localizedDescription)")
      return false
    }
  }

  private static func setLegacyAgentEnabled(_ enabled: Bool) -> Bool {
    let fm = FileManager.default
    let url = legacyAgentURL
    do {
      guard enabled else {
        if fm.fileExists(atPath: url.path) {
          try fm.removeItem(at: url)
        }
        return true
      }
      try fm.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      // `open -a <bundle>` rather than the raw executable: launchd starts
      // agents outside an app context, and launching the binary directly
      // gives a process with no Dock icon and no proper activation.
      // `--args` forwards everything after it to the app itself.
      var programArguments = ["/usr/bin/open", "-a", Bundle.main.bundlePath]
      if wantsMinimized {
        programArguments.append(contentsOf: ["--args", minimizedFlag])
      }
      let plist: [String: Any] = [
        "Label": bundleIdentifier,
        "ProgramArguments": programArguments,
        "RunAtLoad": true,
      ]
      let data = try PropertyListSerialization.data(
        fromPropertyList: plist, format: .xml, options: 0)
      try data.write(to: url, options: .atomic)
      return true
    } catch {
      NSLog("[LaunchAtStartup] LaunchAgent update failed: \(error.localizedDescription)")
      return false
    }
  }
}

class MainFlutterWindow: NSWindow {
  private var isTitleBarDragging = false
  private var dragStartScreenPoint = NSPoint.zero
  private var dragStartFrameOrigin = NSPoint.zero

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

    // Handle title-bar double-click (zoom/restore) and drag natively so they
    // work reliably without conflicting with Flutter's gesture arena.
    setupTitleBarInteractions()

    RegisterGeneratedPlugins(registry: flutterViewController)

    // launch_at_startup has no macOS plugin of its own — see the handler above.
    LaunchAtStartupHandler.register(with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  private func setupTitleBarInteractions() {
    let titleBarHeight: CGFloat = 28

    // mouseDown in the top 28 pt: double-click → zoom/restore; single click →
    // record start position so a subsequent drag can move the window.
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      guard let self = self, event.window === self else { return event }
      let contentHeight = self.contentView?.frame.height ?? 0
      guard event.locationInWindow.y >= contentHeight - titleBarHeight else {
        self.isTitleBarDragging = false
        return event
      }
      if event.clickCount == 2 {
        self.isTitleBarDragging = false
        self.zoom(nil)  // zoom = maximise / restore (NOT full screen)
        return nil      // consume – Flutter never sees this tap
      }
      self.isTitleBarDragging = true
      self.dragStartScreenPoint = NSEvent.mouseLocation
      self.dragStartFrameOrigin = self.frame.origin
      return event      // pass single click through (e.g. back button)
    }

    // mouseDragged: move the window by applying the pointer delta to the frame origin.
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
      guard let self = self, event.window === self,
            self.isTitleBarDragging,
            !self.styleMask.contains(.fullScreen) else { return event }
      let current = NSEvent.mouseLocation
      let dx = current.x - self.dragStartScreenPoint.x
      let dy = current.y - self.dragStartScreenPoint.y
      self.setFrameOrigin(NSPoint(
        x: self.dragStartFrameOrigin.x + dx,
        y: self.dragStartFrameOrigin.y + dy
      ))
      return nil  // consume
    }

    // mouseUp: end any in-progress title-bar drag.
    NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
      if event.window === self { self?.isTitleBarDragging = false }
      return event
    }
  }
}
