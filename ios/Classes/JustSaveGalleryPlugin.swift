import Flutter
import UIKit

/// Flutter plugin entry point for just_save_gallery on iOS.
///
/// Routes method channel calls to [GallerySaver] and maps results
/// back to the Flutter side.
public class JustSaveGalleryPlugin: NSObject, FlutterPlugin {

    private let saver = GallerySaver()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "just_save_gallery",
            binaryMessenger: registrar.messenger()
        )
        let instance = JustSaveGalleryPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterMethodNotImplemented)
            return
        }

        switch call.method {
        case "saveBytes":
            handleSaveBytes(args: args, result: result)
        case "saveFile":
            handleSaveFile(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Handlers

    private func handleSaveBytes(args: [String: Any], result: @escaping FlutterResult) {
        guard let bytes = args["bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_FORMAT", message: "Missing or invalid bytes", details: nil))
            return
        }

        let name = args["name"] as? String ?? "image.jpg"
        let albumName = args["albumName"] as? String
        let isVideo = (args["mediaType"] as? String) == "video"
        let requestPermission = args["requestPermission"] as? Bool ?? true

        saver.saveBytes(
            bytes.data,
            name: name,
            albumName: albumName,
            isVideo: isVideo,
            requestPermission: requestPermission
        ) { saveResult in
            DispatchQueue.main.async {
                switch saveResult {
                case .success(let identifier):
                    result(identifier)
                case .failure(let error):
                    result(FlutterError(code: error.code, message: error.message, details: nil))
                }
            }
        }
    }

    private func handleSaveFile(args: [String: Any], result: @escaping FlutterResult) {
        guard let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Missing filePath argument", details: nil))
            return
        }

        let name = args["name"] as? String ?? filePath.components(separatedBy: "/").last ?? "file"
        let albumName = args["albumName"] as? String
        let isVideo = (args["mediaType"] as? String) == "video"
        let requestPermission = args["requestPermission"] as? Bool ?? true

        saver.saveFile(
            filePath,
            name: name,
            albumName: albumName,
            isVideo: isVideo,
            requestPermission: requestPermission
        ) { saveResult in
            DispatchQueue.main.async {
                switch saveResult {
                case .success(let identifier):
                    result(identifier)
                case .failure(let error):
                    result(FlutterError(code: error.code, message: error.message, details: nil))
                }
            }
        }
    }
}
