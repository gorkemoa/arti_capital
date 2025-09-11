import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import Foundation

@main
@objc class AppDelegate: FlutterAppDelegate {
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
