# 🔔 Push Notification Kurulum Kontrol Listesi

## ✅ Yapılan Native iOS Değişiklikleri

### 1. AppDelegate.swift Güncellemeleri
- ✅ APNS token kaydı iyileştirildi (`setAPNSToken` metodu eklendi)
- ✅ Debug ve Production için farklı token tipleri ayarlandı
- ✅ Detaylı loglama eklendi (emoji'lerle)
- ✅ Bildirim gösterimi iOS 14+ için güncellendi (.banner desteği)

### 2. Token Kaydetme İyileştirmeleri
```swift
// Hem eski hem yeni format için destek:
Messaging.messaging().apnsToken = deviceToken
Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox/.prod)
```

## 🔍 Kontrol Edilmesi Gerekenler

### Xcode'da Yapılması Gerekenler:

1. **Push Notifications Capability Ekleyin:**
   ```
   Xcode'u açın:
   - Proje dosyasını seçin (ios/Runner.xcworkspace)
   - Runner target'ı seçin
   - Signing & Capabilities sekmesine gidin
   - "+ Capability" butonuna tıklayın
   - "Push Notifications" seçin
   ```

2. **Background Modes Kontrol Edin:**
   ```
   Signing & Capabilities sekmesinde:
   - Background Modes capability var mı kontrol edin
   - "Remote notifications" checkbox'ı işaretli olmalı
   ```

3. **Provisioning Profile Kontrolü:**
   ```
   - Development veya Distribution sertifikanız aktif olmalı
   - Provisioning Profile Push Notifications içermeli
   - "Automatically manage signing" açıksa, Xcode otomatik halleder
   ```

### Firebase Console'da Yapılması Gerekenler:

1. **APNs Authentication Key Yükleme:**
   ```
   Firebase Console → Project Settings → Cloud Messaging:
   - iOS app configuration sekmesine gidin
   - APNs Authentication Key yükleyin VEYA
   - APNs Certificates yükleyin
   ```

2. **APNs Auth Key Oluşturma (Apple Developer):**
   ```
   - developer.apple.com'a gidin
   - Certificates, Identifiers & Profiles
   - Keys → (+) butonu
   - "Apple Push Notifications service (APNs)" seçin
   - .p8 dosyasını indirin
   - Key ID ve Team ID'yi not alın
   - Firebase'e yükleyin
   ```

### Test Adımları:

1. **Gerçek Cihazda Test Edin:**
   ```bash
   # Simulator'de push notification çalışmaz!
   flutter run --release
   ```

2. **Logları Kontrol Edin:**
   ```
   Konsolda şunları görmeli:
   ✅ Bildirim izni verildi
   ✅ APNS token alındı
   📱 APNS Token: [hex string]
   🔧 APNS Token Type: Sandbox (Debug) veya Production
   🔥 Firebase registration token: [FCM token]
   ✅ FCM Token başarıyla alındı ve kaydedildi
   ```

3. **Test Bildirimi Gönderin:**
   - Firebase Console → Cloud Messaging
   - "Send test message" butonuna tıklayın
   - FCM token'ı yapıştırın
   - Test mesajı gönderin

## 🐛 Sorun Giderme

### Hata: "APNS token has not been set yet"
**Çözüm:** AppDelegate.swift güncellemeleri yapıldı, projeyi yeniden derleyin.

### Hata: "No APNS token provided"
**Çözüm:** 
1. Xcode'da Push Notifications capability ekleyin
2. Gerçek cihazda test edin (Simulator desteklenmez)
3. Provisioning Profile'ı yenileyin

### Bildirimler Gelmiyor
**Kontrol Edin:**
1. ✅ Firebase Console'da APNs Auth Key yüklü mü?
2. ✅ Cihaz ayarlarında bildirim izni verilmiş mi?
3. ✅ FCM token başarıyla alındı mı?
4. ✅ Uygulama background'da mı? (Foreground'da farklı davranır)

## 📝 Önemli Notlar

- **Debug Build:** Sandbox APNs token kullanır
- **Release Build:** Production APNs token kullanır
- Firebase Console'da her iki ortam için de ayrı key/certificate yüklemeniz gerekmez, tek bir Auth Key her ikisi için de çalışır
- Simulator'de push notification test edilemez, gerçek cihaz gereklidir

## 🚀 Projeyi Çalıştırma

```bash
# Temizlik
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Debug build (gerçek cihazda)
flutter run --debug

# Release build
flutter run --release
```

## 📞 Destek

Sorun yaşarsanız:
1. Xcode konsolundaki logları kontrol edin
2. Firebase Console → Cloud Messaging → Send test message ile test yapın
3. APNs Auth Key/Certificate'in doğru yüklendiğinden emin olun
