#include "flutter_window.h"

#include <optional>
#include <string>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "jump_list.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // ── Dock / Jump List method channel ─────────────────────────────────────
  auto channel = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.bandpassrecords.dpm/dock_menu",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "setRecentProjects") {
          const auto* list =
              std::get_if<flutter::EncodableList>(call.arguments());
          if (list) {
            std::vector<std::pair<std::wstring, std::wstring>> projects;
            for (const auto& item : *list) {
              const auto* map =
                  std::get_if<flutter::EncodableMap>(&item);
              if (!map) continue;
              auto nameIt = map->find(flutter::EncodableValue("name"));
              auto pathIt = map->find(flutter::EncodableValue("path"));
              if (nameIt == map->end() || pathIt == map->end()) continue;
              const auto* name =
                  std::get_if<std::string>(&nameIt->second);
              const auto* path =
                  std::get_if<std::string>(&pathIt->second);
              if (!name || !path) continue;
              // Convert UTF-8 → wstring for Windows APIs
              int nLen = MultiByteToWideChar(CP_UTF8, 0, name->c_str(), -1,
                                             nullptr, 0);
              int pLen = MultiByteToWideChar(CP_UTF8, 0, path->c_str(), -1,
                                             nullptr, 0);
              std::wstring wname(nLen, L'\0');
              std::wstring wpath(pLen, L'\0');
              MultiByteToWideChar(CP_UTF8, 0, name->c_str(), -1,
                                  wname.data(), nLen);
              MultiByteToWideChar(CP_UTF8, 0, path->c_str(), -1,
                                  wpath.data(), pLen);
              projects.emplace_back(wname, wpath);
            }
            UpdateJumpList(projects);
          }
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  // Keep the channel alive for the window's lifetime
  dock_channel_ = channel;
  // ────────────────────────────────────────────────────────────────────────

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
