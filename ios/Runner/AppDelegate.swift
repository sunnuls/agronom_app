import Flutter
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let importLock = NSLock()
  private static var pendingImportJson: String?

  /// Читает локальный файл (открытие из «Файлы», документ-пикер, другое приложение).
  static func readUtf8FromImportURL(_ url: URL) -> String? {
    guard url.isFileURL else { return nil }
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
      return nil
    }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  /// Сохраняет содержимое для импорта при открытии файла извне.
  static func ingestImportFileURL(_ url: URL) {
    guard let trimmed = readUtf8FromImportURL(url) else { return }
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

  /// Ожидание результата [pickFile] из Flutter.
  private var pendingPickResult: FlutterResult?

  private func keyWindowRootViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes
      let windowScene = scenes.compactMap { $0 as? UIWindowScene }.first
      let window = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? windowScene?.windows.first
      return window?.rootViewController
    }
    return UIApplication.shared.keyWindow?.rootViewController
  }

  private func topMostViewController(from root: UIViewController?) -> UIViewController? {
    guard let root = root else { return nil }
    if let presented = root.presentedViewController {
      return topMostViewController(from: presented)
    }
    if let nav = root as? UINavigationController {
      return topMostViewController(from: nav.visibleViewController) ?? nav
    }
    if let tab = root as? UITabBarController {
      return topMostViewController(from: tab.selectedViewController) ?? tab
    }
    return root
  }

  /// Показывает системный выбор файла; ответ Flutter — через [pendingPickResult] и [documentPicker].
  private func presentImportFilePicker() {
    guard let presenter = topMostViewController(from: keyWindowRootViewController()) else {
      let pr = pendingPickResult
      pendingPickResult = nil
      pr?(FlutterError(code: "NO_UI", message: "Не удалось открыть окно выбора файла", details: nil))
      return
    }

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      var types: [UTType] = [.json, .plainText, .utf8PlainText]
      if let agr = UTType(filenameExtension: "agronom") {
        types.append(agr)
      }
      picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: false)
    } else {
      let legacy = [
        kUTTypeJSON as String,
        kUTTypePlainText as String,
        kUTTypeText as String,
      ]
      picker = UIDocumentPickerViewController(documentTypes: legacy, in: .import)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true)
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
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "takePendingImport":
        result(AppDelegate.takePendingImportJson())
      case "pickFile":
        guard let self = self else {
          result(FlutterError(code: "INTERNAL", message: "App delegate unavailable", details: nil))
          return
        }
        if self.pendingPickResult != nil {
          result(FlutterError(code: "BUSY", message: "Уже открыт выбор файла", details: nil))
          return
        }
        self.pendingPickResult = result
        DispatchQueue.main.async {
          self.presentImportFilePicker()
        }
      case "saveFile":
        result(FlutterMethodNotImplemented)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

extension AppDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let pr = pendingPickResult
    pendingPickResult = nil
    guard let url = urls.first else {
      DispatchQueue.main.async { pr?(nil) }
      return
    }
    let text = AppDelegate.readUtf8FromImportURL(url)
    DispatchQueue.main.async {
      if let text = text {
        pr?(text)
      } else {
        pr?(FlutterError(code: "READ_FAILED", message: "Не удалось прочитать файл", details: nil))
      }
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let pr = pendingPickResult
    pendingPickResult = nil
    DispatchQueue.main.async { pr?(nil) }
  }
}
