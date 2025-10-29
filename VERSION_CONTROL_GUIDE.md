# Version Control ve Güncelleme Sistemi Dokümantasyonu

## Genel Bakış

`new_version_plus` paketi kullanarak uygulamanız için otomatik versiyon kontrol sistemi entegre edilmiştir. Bu sistem şu özellikleri sunmaktadır:

- ✅ Otomatik versiyon kontrolü
- ✅ Kullanıcı dostu bottom sheet bildirimi
- ✅ iOS ve Android App Store desteği
- ✅ Zorunlu/Opsiyonel güncelleme desteği
- ✅ Versiyon bilgileri görüntüleme

## Dosyalar ve Yapı

### 1. `lib/services/version_control_service.dart`
Ana hizmet sınıfı. Singleton pattern ile uygulanmıştır.

```dart
// Versiyon kontrolü yapma
final status = await VersionControlService().getVersionStatus();

// Platform-specific alert gösterme
await VersionControlService().showUpdateAlert(context);
```

**Ana Metodlar:**
- `checkForNewVersion()` - Yeni versiyon kontrolü
- `showUpdateAlert(context)` - Platform-specific alert gösterir
- `getVersionStatus()` - Versiyon durumunu döndürür
- `showCustomUpdateDialog()` - Custom dialog gösterir

### 2. `lib/widgets/update_bottom_sheet.dart`
Güncelleme bildirimi için custom bottom sheet widget.

**Özellikler:**
- Versiyon bilgisi (mevcut → yeni)
- Ne'nin değiştiğini gösterir
- Zorunlu/Opsiyonel güncelleme desteği
- App Store bağlantısı

**Kullanım:**
```dart
final status = await VersionControlService().getVersionStatus();
if (status != null) {
  await UpdateBottomSheet.show(
    context,
    versionStatus: status,
    isMandatory: false,
    onDismiss: () => print('Kapatıldı'),
  );
}
```

## Entegrasyon

### Otomatik Kontrol (Uygulama Başlangıcı)
`lib/main.dart` içinde `_VersionCheckWrapper` widget'ı otomatik olarak uygulamanın başında versiyon kontrolü yapıp, güncelleme mevcutsa bottom sheet gösterir.

### Manuel Kontrol (Ayarlar Sayfası)
Settings view'da manüel güncelleme kontrolü eklemek için:

```dart
Future<void> _checkVersionManually() async {
  final status = await VersionControlService().getVersionStatus();
  if (mounted) {
    if (status != null && status.canUpdate) {
      await UpdateBottomSheet.show(
        context,
        versionStatus: status,
      );
    } else if (status != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uygulamanız güncel')),
      );
    }
  }
}
```

## Yapılandırma

### pubspec.yaml
```yaml
dependencies:
  new_version_plus: ^0.1.1
  url_launcher: ^6.0.0  (otomatik bağımlılık)
```

### App IDs Ayarlama
`lib/services/version_control_service.dart` içinde:

```dart
final NewVersionPlus _newVersion = NewVersionPlus(
  iOSId: 'com.office701.arti_capital',      // iOS Bundle ID
  androidId: 'com.office701.arti_capital',  // Android Package Name
);
```

**iOS App Store Ülkesi** (Sadece US dışında gerekli):
```dart
final NewVersionPlus _newVersion = NewVersionPlus(
  iOSId: 'com.office701.arti_capital',
  iOSAppStoreCountry: 'TR', // ISO ülke kodu
);
```

## Kullanım Senaryoları

### Senaryo 1: Otomatik Kontrol (Varsayılan)
Uygulama her başladığında otomatik olarak kontrol yapılır ve güncelleme mevcutsa bottom sheet gösterilir.

### Senaryo 2: Manuel Kontrol
Kullanıcı Settings sayfasında "Güncellemeleri Kontrol Et" düğmesine tıklayabilir.

### Senaryo 3: Zorunlu Güncelleme
İşletme mantığınız gereği zorunlu güncelleme gerekiyorsa:

```dart
await UpdateBottomSheet.show(
  context,
  versionStatus: status,
  isMandatory: true,  // Kullanıcı kapatamaz
);
```

## API Referansı

### VersionStatus Nesnesi
```dart
versionStatus.localVersion    // Mevcut sürüm (ör: 1.0.0)
versionStatus.storeVersion    // Mağaza sürümü (ör: 1.1.0)
versionStatus.canUpdate       // Güncelleme gerekli mi
versionStatus.appStoreLink    // App Store/Play Store bağlantısı
```

### Bottom Sheet Parametreleri
```dart
UpdateBottomSheet.show(
  context,
  versionStatus: status,        // Zorunlu: VersionStatus nesnesi
  isMandatory: false,           // Opsiyonel: Zorunlu güncelleme
  onDismiss: () => {},          // Opsiyonel: Kapatma callback
);
```

## Hata Yönetimi

Tüm işlemler try-catch bloklarıyla korunmaktadır. Hata durumunda:
- Debug modunda console'a hata yazılır
- Kullanıcı arayüzü etkilenmez
- Uygulamaya devam edilir

## Test ve Hata Ayıklama

### Lokal Test
1. Build numarasını `pubspec.yaml` da arttırın
2. Test cihazında uygulamayı yeni versiyon olarak kurun
3. Version control sistemi yeni sürümü algılayacaktır

### Debug Çıktısı
Hata ayıklama için terminal çıktısını kontrol edin:
```
flutter logs | grep "Version"
```

## Gelecek İyileştirmeler

- [ ] Periyodik arka planda kontrol
- [ ] Versiyon kontrol geçmişi
- [ ] Push notification entegrasyonu
- [ ] A/B test desteği

## Sorun Giderme

### Versiyon kontrolü çalışmıyor
1. App IDs'nin doğru olduğunu kontrol edin
2. Cihazın internet bağlantısını kontrol edin
3. App Store/Play Store erişim durumunu kontrol edin

### Bottom sheet gösterilmiyor
1. VersionStatus'un null olmadığını kontrol edin
2. `canUpdate` property'sini kontrol edin
3. Context'in valid olduğundan emin olun

## Kaynaklar

- [new_version_plus - pub.dev](https://pub.dev/packages/new_version_plus)
- [url_launcher - pub.dev](https://pub.dev/packages/url_launcher)
- [Flutter MaterialApp Builder](https://api.flutter.dev/flutter/material/MaterialApp/builder.html)
