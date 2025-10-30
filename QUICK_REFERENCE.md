# ⚡ Versiyon Kontrolü - Hızlı Referans Kartı

## 🚀 Başlangıç (2 dakika)

```bash
# 1. Paketleri indir
flutter pub get

# 2. (iOS için) Pod dependencies
cd ios && pod install && cd ..

# 3. Çalıştır
flutter run
```

## 📝 API Cheat Sheet

### Versiyon Durumunu Alma
```dart
final status = await VersionControlService().getVersionStatus();
print(status?.localVersion);   // "1.0.0"
print(status?.storeVersion);   // "1.0.1"
print(status?.canUpdate);      // true
print(status?.appStoreLink);   // "https://..."
```

### Bottom Sheet Gösterme
```dart
await UpdateBottomSheet.show(
  context,
  versionStatus: status,
);
```

### Zorunlu Güncelleme
```dart
await UpdateBottomSheet.show(
  context,
  versionStatus: status,
  isMandatory: true,  // Kapatılamaz
);
```

### Kapatma Callback
```dart
await UpdateBottomSheet.show(
  context,
  versionStatus: status,
  onDismiss: () => print('Kapatıldı'),
);
```

## 🎯 Ortak Görevler

### Ayarlar Sayfasına Entegrasyon
```dart
// 1. Import ekle
import 'package:arti_capital/services/version_control_service.dart';
import 'package:arti_capital/widgets/update_bottom_sheet.dart';

// 2. Fonksiyon ekle
Future<void> _checkVersion() async {
  final status = await VersionControlService().getVersionStatus();
  if (status?.canUpdate ?? false) {
    await UpdateBottomSheet.show(context, versionStatus: status!);
  }
}

// 3. ListTile ekle
ListTile(
  leading: Icon(Icons.system_update),
  title: Text('Güncellemeleri Kontrol Et'),
  onTap: _checkVersion,
)
```

### Manuel App Store Açılışı
```dart
// VersionStatus'dan linki al
final link = status?.appStoreLink;
if (link != null) {
  if (await canLaunchUrl(Uri.parse(link))) {
    await launchUrl(Uri.parse(link));
  }
}
```

### Error Handling
```dart
try {
  final status = await VersionControlService().getVersionStatus();
  if (status?.canUpdate ?? false) {
    await UpdateBottomSheet.show(context, versionStatus: status!);
  }
} catch (e) {
  print('Hata: $e');
  // Sessiz devam et veya snackbar göster
}
```

## 🔧 Yapılandırma

### App ID Değiştirme
**Dosya:** `lib/services/version_control_service.dart`
```dart
final NewVersionPlus _newVersion = NewVersionPlus(
  iOSId: 'com.office701.arti_capital',
  androidId: 'com.office701.arti_capital',
);
```

### Ülke Ayarı (iOS)
```dart
// Sadece US dışında gerekli
iOSAppStoreCountry: 'TR', // ISO kodu: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
```

## 📊 VersionStatus Alanları

| Alan | Tür | Örnek | Açıklama |
|------|-----|-------|---------|
| `localVersion` | String | "1.0.0" | Cihazda yüklü versiyon |
| `storeVersion` | String | "1.0.1" | App Store/Play Store versiyonu |
| `canUpdate` | bool | true | Güncelleme gerekli mi |
| `appStoreLink` | String | "https://..." | App Store/Play Store linki |

## 🎨 UI Özelleştirme

### Bottom Sheet'i Özelleştir
`lib/widgets/update_bottom_sheet.dart` içinde:
- Renkler: `colorScheme.primary` değiştir
- Metinler: String literallerini güncelle
- İkonlar: `Icons.*` değiştir
- Layout: Padding, spacing değerlerini ayarla

## 🧪 Test Etme

### Lokal Test
```yaml
# pubspec.yaml
version: 1.0.0+1  # Build numarasını artır: +2

# Terminal
flutter run
```

### Test Sürümü
```dart
// debug mode'da
final mockStatus = VersionStatus(
  localVersion: '1.0.0',
  storeVersion: '1.0.1',
  canUpdate: true,
  appStoreLink: 'https://...',
);
```

## ⚠️ Yaygın Sorunlar

| Sorun | Çözüm |
|-------|-------|
| Versiyon kontrolü çalışmıyor | App IDs doğru? Internet var? |
| Bottom sheet gösterilmiyor | `canUpdate` true mi? |
| App Store açılmıyor | URL doğru? `url_launcher` yüklü? |
| "Paket bulunamadı" hatası | `flutter pub get` çalıştır |

## 📚 Detaylı Dokümantasyon

- `VERSION_CONTROL_GUIDE.md` - Teknik detaylar
- `VERSION_CONTROL_INTEGRATION.md` - Adım adım talimatlar
- `SYSTEM_ARCHITECTURE.md` - Mimari diyagramları
- `IMPLEMENTATION_SUMMARY.md` - Özet bilgisi

## 🆘 Hızlı Destek

**Q: Otomatik kontrol nasıl devre dışı bırakılır?**
A: `lib/main.dart`'da `_VersionCheckWrapper` silin

**Q: Manuel kontrol sadece gerekirse mi?**
A: Evet, `Settings` view'a entegre et

**Q: Zorunlu güncelleme mümkün mü?**
A: Evet, `isMandatory: true` kullan

**Q: Versiyon bilgisine nereden ulaşırım?**
A: `VersionControlService().getVersionStatus()`

**Q: Çok hızlı gösteriliyor, yavaşlatabilir miyim?**
A: `_checkVersion()` içine `await Future.delayed()` ekle

## 📞 Kontaklar

- **Teknik Sorular:** `VERSION_CONTROL_GUIDE.md`
- **Entegrasyon:** `VERSION_CONTROL_INTEGRATION.md`
- **Mimari:** `SYSTEM_ARCHITECTURE.md`

---

**💡 Pro Tip:** `lib/examples/version_control_example.dart` örneğini incele!

**⚡ Hızlı Başlangıç:**
```bash
flutter pub get && cd ios && pod install && cd .. && flutter run
```
