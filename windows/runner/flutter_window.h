#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // |show_on_first_frame| false leaves the window hidden after the engine
  // renders. Used for the "start minimized to tray" auto-start launch: Dart
  // (main.dart) skips windowManager.show() in that case, but the runner's own
  // first-frame Show() would override that and pop the window up anyway.
  explicit FlutterWindow(const flutter::DartProject& project,
                         bool show_on_first_frame = true);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;
  bool show_on_first_frame_;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  // Keeps the dock/jump-list method channel alive for the window's lifetime
  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> dock_channel_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
