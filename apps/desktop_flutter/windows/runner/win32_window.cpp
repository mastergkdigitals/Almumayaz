#include "win32_window.h"

#include <dwmapi.h>
#include <flutter_windows.h>

#include "resource.h"

namespace {

/// Window attribute that enables dark mode window decorations.
///
/// Redefined in case the developer's machine has a Windows SDK older than
/// version 10.0.22000.0.
/// See: https://docs.microsoft.com/windows/win32/api/dwmapi/ne-dwmapi-dwmwindowattribute
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

constexpr int kMinimumWindowWidth = 1280;
constexpr int kMinimumWindowHeight = 720;
constexpr int kWindowAspectWidth = 16;
constexpr int kWindowAspectHeight = 9;

static_assert(kMinimumWindowWidth * kWindowAspectHeight ==
              kMinimumWindowHeight * kWindowAspectWidth);

/// Registry key for app theme preference.
///
/// A value of 0 indicates apps should use dark mode. A non-zero or missing
/// value indicates apps should use light mode.
constexpr const wchar_t kGetPreferredBrightnessRegKey[] =
  L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
constexpr const wchar_t kGetPreferredBrightnessRegValue[] = L"AppsUseLightTheme";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

SIZE GetMinimumTrackingSize() {
  // This is the complete native window size, including its title bar and
  // borders. Keep it in physical pixels so the restored window can still fit
  // on a display whose total resolution is 1280x720.
  return {kMinimumWindowWidth, kMinimumWindowHeight};
}

SIZE SizeFromWidth(LONG proposed_width, const SIZE& minimum_size) {
  LONG width =
      proposed_width < minimum_size.cx ? minimum_size.cx : proposed_width;
  LONG height = MulDiv(width, kWindowAspectHeight, kWindowAspectWidth);

  if (height < minimum_size.cy) {
    height = minimum_size.cy;
    width = MulDiv(height, kWindowAspectWidth, kWindowAspectHeight);
  }

  return {width, height};
}

SIZE SizeFromHeight(LONG proposed_height, const SIZE& minimum_size) {
  LONG height =
      proposed_height < minimum_size.cy ? minimum_size.cy : proposed_height;
  LONG width = MulDiv(height, kWindowAspectWidth, kWindowAspectHeight);

  if (width < minimum_size.cx) {
    width = minimum_size.cx;
    height = MulDiv(width, kWindowAspectHeight, kWindowAspectWidth);
  }

  return {width, height};
}

bool LockSizingRectToAspectRatio(WPARAM sizing_edge, RECT* rect) {
  if (rect == nullptr) {
    return false;
  }

  const LONG proposed_width = rect->right - rect->left;
  const LONG proposed_height = rect->bottom - rect->top;
  const SIZE minimum_size = GetMinimumTrackingSize();

  bool width_drives;
  switch (sizing_edge) {
    case WMSZ_LEFT:
    case WMSZ_RIGHT:
      width_drives = true;
      break;
    case WMSZ_TOP:
    case WMSZ_BOTTOM:
      width_drives = false;
      break;
    case WMSZ_TOPLEFT:
    case WMSZ_TOPRIGHT:
    case WMSZ_BOTTOMLEFT:
    case WMSZ_BOTTOMRIGHT:
      width_drives =
          static_cast<LONGLONG>(proposed_width) * kWindowAspectHeight >=
          static_cast<LONGLONG>(proposed_height) * kWindowAspectWidth;
      break;
    default:
      return false;
  }

  const SIZE target_size =
      width_drives ? SizeFromWidth(proposed_width, minimum_size)
                   : SizeFromHeight(proposed_height, minimum_size);

  switch (sizing_edge) {
    case WMSZ_LEFT: {
      const LONG center_y = rect->top + proposed_height / 2;
      rect->left = rect->right - target_size.cx;
      rect->top = center_y - target_size.cy / 2;
      rect->bottom = rect->top + target_size.cy;
      break;
    }
    case WMSZ_RIGHT: {
      const LONG center_y = rect->top + proposed_height / 2;
      rect->right = rect->left + target_size.cx;
      rect->top = center_y - target_size.cy / 2;
      rect->bottom = rect->top + target_size.cy;
      break;
    }
    case WMSZ_TOP: {
      const LONG center_x = rect->left + proposed_width / 2;
      rect->top = rect->bottom - target_size.cy;
      rect->left = center_x - target_size.cx / 2;
      rect->right = rect->left + target_size.cx;
      break;
    }
    case WMSZ_BOTTOM: {
      const LONG center_x = rect->left + proposed_width / 2;
      rect->bottom = rect->top + target_size.cy;
      rect->left = center_x - target_size.cx / 2;
      rect->right = rect->left + target_size.cx;
      break;
    }
    case WMSZ_TOPLEFT:
      rect->left = rect->right - target_size.cx;
      rect->top = rect->bottom - target_size.cy;
      break;
    case WMSZ_TOPRIGHT:
      rect->right = rect->left + target_size.cx;
      rect->top = rect->bottom - target_size.cy;
      break;
    case WMSZ_BOTTOMLEFT:
      rect->left = rect->right - target_size.cx;
      rect->bottom = rect->top + target_size.cy;
      break;
    case WMSZ_BOTTOMRIGHT:
      rect->right = rect->left + target_size.cx;
      rect->bottom = rect->top + target_size.cy;
      break;
  }

  return true;
}

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
  }
  FreeLibrary(user32_module);
}

}  // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registrar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::Create(const std::wstring& title,
                         const Point& origin,
                         const Size& size) {
  Destroy();

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  HWND window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window) {
    return false;
  }

  UpdateTheme(window);

  return OnCreate();
}

bool Win32Window::Show() {
  return ShowWindow(window_handle_, SW_SHOWMAXIMIZED);
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_GETMINMAXINFO: {
      auto min_max_info = reinterpret_cast<MINMAXINFO*>(lparam);
      const SIZE minimum_size = GetMinimumTrackingSize();
      min_max_info->ptMinTrackSize.x = minimum_size.cx;
      min_max_info->ptMinTrackSize.y = minimum_size.cy;
      return 0;
    }

    case WM_SIZING: {
      if (!IsZoomed(hwnd) &&
          LockSizingRectToAspectRatio(wparam,
                                      reinterpret_cast<RECT*>(lparam))) {
        return TRUE;
      }
      break;
    }

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;

    case WM_DWMCOLORIZATIONCOLORCHANGED:
      UpdateTheme(hwnd);
      return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy() {
  // No-op; provided for subclasses.
}

void Win32Window::UpdateTheme(HWND const window) {
  DWORD light_mode;
  DWORD light_mode_size = sizeof(light_mode);
  LSTATUS result = RegGetValue(HKEY_CURRENT_USER, kGetPreferredBrightnessRegKey,
                               kGetPreferredBrightnessRegValue,
                               RRF_RT_REG_DWORD, nullptr, &light_mode,
                               &light_mode_size);

  if (result == ERROR_SUCCESS) {
    BOOL enable_dark_mode = light_mode == 0;
    DwmSetWindowAttribute(window, DWMWA_USE_IMMERSIVE_DARK_MODE,
                          &enable_dark_mode, sizeof(enable_dark_mode));
  }
}
