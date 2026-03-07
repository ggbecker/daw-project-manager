import Cocoa
import FlutterMacOS

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
