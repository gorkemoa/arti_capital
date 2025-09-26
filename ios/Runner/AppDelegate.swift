import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import Foundation
import SwiftUI
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  var privacyOverlayView: UIView?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // FCM token'ı al
    Messaging.messaging().delegate = self
    
    // Uzak bildirimleri etkinleştir
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          if granted {
            print("Bildirim izni verildi")
            DispatchQueue.main.async {
              application.registerForRemoteNotifications()
            }
          } else {
            print("Bildirim izni reddedildi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
    }
    
    // APNS token'ının hazır olması için kısa bir gecikme
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      application.registerForRemoteNotifications()
    }
    
    GeneratedPluginRegistrant.register(with: self)
    // MethodChannel: App Group UserDefaults yazma
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "app_group_prefs", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        if call.method == "setString" {
          guard let args = call.arguments as? [String: Any],
                let group = args["group"] as? String,
                let key = args["key"] as? String,
                let value = args["value"] as? String,
                let ud = UserDefaults(suiteName: group) else {
            result(FlutterError(code: "ARG_ERROR", message: "Eksik argüman", details: nil))
            return
          }
          ud.set(value, forKey: key)
          ud.synchronize()
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      // iOS: native downloader => Paylaşım sayfası ile Dosyalar'a kaydetme
      let downloader = FlutterMethodChannel(name: "native_downloader", binaryMessenger: controller.binaryMessenger)
      downloader.setMethodCallHandler { call, result in
        guard call.method == "downloadFile" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let args = call.arguments as? [String: Any],
              let urlStr = args["url"] as? String,
              let url = URL(string: urlStr) else {
          result(FlutterError(code: "ARG_ERROR", message: "url gerekli", details: nil))
          return
        }
        let fileName = (args["fileName"] as? String) ?? url.lastPathComponent

        // URL'den veriyi indir
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
          if let error = error {
            result(FlutterError(code: "DL_ERROR", message: error.localizedDescription, details: nil))
            return
          }
          guard let data = data else {
            result(FlutterError(code: "DL_EMPTY", message: "Boş yanıt", details: nil))
            return
          }
          DispatchQueue.main.async {
            // Paylaşım sayfası aç; kullanıcı Files'a kaydedebilir
            let tmpUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            do {
              try data.write(to: tmpUrl)
            } catch {
              result(FlutterError(code: "WRITE_ERROR", message: error.localizedDescription, details: nil))
              return
            }
            let avc = UIActivityViewController(activityItems: [tmpUrl], applicationActivities: nil)
            avc.completionWithItemsHandler = { _, _, _, _ in
              result(true)
            }
            controller.present(avc, animated: true, completion: nil)
          }
        }
        task.resume()
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - MethodChannel for App Group writes
extension AppDelegate {
  override func application(_ application: UIApplication,
                            didRegister notificationSettings: UIUserNotificationSettings) {
    // no-op
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    addPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    removePrivacyOverlay()
  }

  func addPrivacyOverlay() {
    guard privacyOverlayView == nil, let window = self.window else { return }
    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = UIColor(red: 0xF3/255.0, green: 0xEF/255.0, blue: 0xE6/255.0, alpha: 1.0)

    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    // LaunchScreen'deki görseli dene; yoksa sistem ikonu kullan
    imageView.image = UIImage(named: "LaunchImage")
    if imageView.image == nil {
      imageView.image = UIImage(systemName: "app")
      imageView.tintColor = .white
    }
    imageView.contentMode = .scaleAspectFit

    overlay.addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      imageView.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.60),
      imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
    ])

    window.addSubview(overlay)
    privacyOverlayView = overlay
  }

  func removePrivacyOverlay() {
    privacyOverlayView?.removeFromSuperview()
    privacyOverlayView = nil
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

// MARK: - APNS Token Handling
extension AppDelegate {
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("APNS token alındı: \(deviceToken)")
    Messaging.messaging().apnsToken = deviceToken
  }
  
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("APNS token alınamadı: \(error.localizedDescription)")
  }
}

// MARK: - UNUserNotificationCenterDelegate
@available(iOS 10, *)
extension AppDelegate {
  // Uygulama açıkken bildirim geldiğinde
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    
    // FCM mesajından gelen verileri işle
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    
    // Bildirimi göster
    completionHandler([[.alert, .sound]])
  }
  
  // Kullanıcı bildirime tıkladığında
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    // FCM mesajından gelen verileri işle
    if let messageID = userInfo["gcm.message_id"] {
      print("Message ID: \(messageID)")
    }
    
    completionHandler()
  }
}
