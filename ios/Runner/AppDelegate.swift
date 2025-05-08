import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة Google Maps باستخدام مفتاح API
    GMSServices.provideAPIKey("AIzaSyCi4z7ujnjKf5QbPawxAxXtLtRts9R6D1o")
    
    // طلب إذن الإشعارات وتعيين المندوب
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Failed to request notification authorization: \(error.localizedDescription)")
      } else {
        print("Notification authorization granted: \(granted)")
      }
    }
    
    // تسجيل مكونات Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // معالجة النقر على الإشعار أو تفاعل المستخدم معه
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // استخراج payload من الإشعار
    let userInfo = response.notification.request.content.userInfo
    if let payload = userInfo["payload"] as? String {
      // الوصول إلى Flutter Method Channel
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.example.accident_detection/notifications",
          binaryMessenger: controller.binaryMessenger
        )
        // إرسال payload إلى Flutter
        channel.invokeMethod("onNotificationTapped", arguments: payload)
      }
    }
    completionHandler()
  }
  
  // معالجة الإشعارات عندما يكون التطبيق في المقدمة
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // عرض الإشعار حتى لو كان التطبيق في المقدمة
    completionHandler([.banner, .sound, .badge])
  }
}
