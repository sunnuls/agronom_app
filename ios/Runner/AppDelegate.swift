import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let importLock = NSLock()
  private static var pendingImportJson: String?

  /// Читает локальный файл (открытие из «Файлы» / другого приложения).
  static func ingestImportFileURL(_ url: URL) {
    guard url.isFileURL else { return }
    var started = false
    if url.startAccessingSecurityScopedResource() {
      started = true
    }
    defer {
      if started {
        url.stopAccessingSecurityScopedResource()
      }
    }
    guard let data = try? Data(contentsOf: url),
          let text = String(data: data, encoding: .utf8) else {
      return
    }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    importLock.lock()
    pendingImportJson = trimmed
    importLock.unlock()
  }

  private static func takePendingImportJson() -> String? {
    importLock.lock()
    defer { importLock.unlock() }
    let v = pendingImportJson
    pendingImportJson = nil
    return v
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    AppDelegate.ingestImportFileURL(url)
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Swift 6 / новый Xcode: messenger — вызов метода, не свойство.
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.agronom.agronom_app/import",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takePendingImport":
        result(AppDelegate.takePendingImportJson())
      case "pickFile", "saveFile":
        result(FlutterMethodNotImplemented)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
