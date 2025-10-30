# Versiyon Kontrolü Sistemi - Mimarı ve Flow Diyagramları

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER APPLICATION                          │
│                    (lib/main.dart - MyApp)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │ _VersionCheckWrapper │
                  │  (initState'te çalış)│
                  └──────────┬───────────┘
                             │
                   ┌─────────▼─────────┐
                   │ getVersionStatus()│ (Network)
                   └─────────┬─────────┘
                             │
                ┌────────────▼────────────┐
                │   Versiyon Karşılaştırma │
                │  (Store vs Local)        │
                └────────────┬────────────┘
                             │
           ┌─────────────────┼──────────────────┐
           │                 │                  │
      Güncelleme        Güncel Versiyon    Hata Oluştu
      Mevcutsa         (Skip)              (Sessiz)
           │
           ▼
    ┌─────────────────┐
    │ UpdateBottomSheet│
    │  (Gösterilir)    │
    └────┬────────┬───┘
         │        │
    Güncelle   Kapat
         │        │
         ▼        ▼
    App Store   Kapatıldı
    (Açılır)    (Devam)
```

## 🔄 Versiyon Kontrol Akışı (Detaylı)

```
UYGULAMA BAŞLATILDI
    │
    ▼
main() çalıştırıldı
    │
    ├─ WidgetsFlutterBinding.ensureInitialized()
    ├─ StorageService.init()
    ├─ Firebase.initializeApp()
    ├─ RemoteConfigService.initialize()
    ├─ NotificationsService.initialize()
    │
    ▼
MyApp() build()
    │
    ├─ MultiProvider (Providers setup)
    │
    ├─ MaterialApp(
    │     builder: (context, child) {
    │       return _VersionCheckWrapper(child: child)
    │     }
    │   )
    │
    ▼
_VersionCheckWrapper initState()
    │
    ├─ WidgetsBinding.addPostFrameCallback()
    │  (UI render edildikten sonra çalış)
    │
    ▼
_checkVersion() çağrıldı
    │
    ▼
VersionControlService().getVersionStatus()
    │
    ├─ NewVersionPlus.getVersionStatus()
    │  │
    │  ├─ Local version'ı oku (pubspec.yaml)
    │  │
    │  ├─ App Store/Play Store sorgusu (HTTP)
    │  │
    │  └─ Sonuç: VersionStatus nesnesi
    │
    ▼
Status kontrolü (versionStatus != null && canUpdate)
    │
    ├─ EVET: UpdateBottomSheet.show()
    │
    └─ HAYIR: Sessiz devam
```

## 📊 Component Diyagramı

```
┌─────────────────────────────────────────────────────────┐
│              Arti Capital App                            │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │            lib/main.dart                         │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │ MyApp                                      │  │   │
│  │  │  └─ _VersionCheckWrapper                  │  │   │
│  │  │     ├─ Widget child                       │  │   │
│  │  │     └─ State: _checkVersion()             │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │      lib/services/version_control_service.dart   │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │ VersionControlService (Singleton)         │  │   │
│  │  │  ├─ getVersionStatus()                    │  │   │
│  │  │  ├─ showUpdateAlert(context)              │  │   │
│  │  │  ├─ checkForNewVersion()                  │  │   │
│  │  │  └─ showCustomUpdateDialog()              │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │       lib/widgets/update_bottom_sheet.dart       │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │ UpdateBottomSheet                         │  │   │
│  │  │  ├─ static show()                         │  │   │
│  │  │  ├─ build()                               │  │   │
│  │  │  └─ _launchAppStore()                     │  │   │
│  │  │                                           │  │   │
│  │  │  Widgets:                                 │  │   │
│  │  │  ├─ _WhatsNewItem                        │  │   │
│  │  │  ├─ FilledButton (Güncelle)              │  │   │
│  │  │  └─ OutlinedButton (Daha Sonra)          │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘

                          ▼
                    (External)

        ┌─────────────────────────────────┐
        │   new_version_plus              │
        │   (Package)                     │
        └────┬────────────────────┬──────┘
             │                    │
        iOS  │                    │  Android
        App  │                    │  Play
        Store│                    │  Store
             │                    │
             ▼                    ▼
        ┌──────────────────────────────┐
        │   http (Network Request)     │
        │   url_launcher (App Açma)    │
        │   package_info_plus (Versiyon)
        └──────────────────────────────┘
```

## 🔗 Data Flow (Veri Akışı)

```
USER ACTION
    │
    ├─ App Launch
    │  └─→ _VersionCheckWrapper.initState()
    │
    ├─ Manual Check (Settings)
    │  └─→ VersionControlService().getVersionStatus()
    │
    └─ Update Button
       └─→ UpdateBottomSheet._launchAppStore()

                    ▼

NETWORK REQUEST
    │
    ├─ iOS → iTunes API
    │  Query: iOSId + iOSAppStoreCountry
    │
    ├─ Android → Play Store API
    │  Query: androidId
    │
    └─ Local → pubspec.yaml
       Read: version: X.Y.Z+BUILD

                    ▼

RESPONSE
    │
    └─ VersionStatus {
         localVersion: "1.0.0",
         storeVersion: "1.0.1",
         canUpdate: true,
         appStoreLink: "https://..."
       }

                    ▼

UI RENDERING
    │
    ├─ canUpdate = true
    │  └─→ UpdateBottomSheet.show()
    │
    └─ canUpdate = false
       └─→ Silent (or "Güncel" message)
```

## 🎨 UI Akışı (Bottom Sheet)

```
┌─────────────────────────────────────────────────────┐
│            UpdateBottomSheet Gösterimi              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │ [🔄] Yeni Versiyon Kullanılabilir          │   │
│  │      1.0.0 → 1.0.1                        │   │
│  └────────────────────────────────────────────┘   │
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │ [ℹ️] Bu güncelleme zorunludur...           │   │
│  └────────────────────────────────────────────┘   │
│                                                     │
│  Bu Sürümde Neler Var:                            │
│  ✓ Yeni özellikler ve iyileştirmeler             │
│  ✓ Hata düzeltmeleri                             │
│  ✓ Performans iyileştirmeleri                    │
│                                                     │
│  ┌──────────────────┐  ┌──────────────────────┐  │
│  │ ⊙ Daha Sonra     │  │ 📥 Güncelle         │  │
│  └──────────────────┘  └──────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
        │                          │
        │ Kapatıldı                │ Tıklandı
        │                          │
        ▼                          ▼
    Devam Et               App Store Açılır
                          (url_launcher)
```

## 🔄 Error Handling Flow

```
getVersionStatus()
    │
    ├─ TRY
    │  │
    │  ├─ Network Request OK
    │  │  └─→ Return VersionStatus
    │  │
    │  └─ Network Error / Parse Error
    │     └─→ CATCH
    │
    └─ CATCH
       │
       ├─ debugPrint('Version check error: $e')
       │
       └─ Return null
          │
          ▼
       UI Effected ?
       │
       ├─ NO → Silent (Uygulama devam eder)
       │
       └─ YES → Show SnackBar / Error Message
```

## 📈 State Management

```
_VersionCheckWrapper State
    │
    ├─ initState()
    │  └─ WidgetsBinding.addPostFrameCallback()
    │
    ├─ _checkVersion()
    │  └─ await VersionControlService().getVersionStatus()
    │
    ├─ Mounted Check
    │  ├─ mounted = true  → UpdateBottomSheet.show()
    │  └─ mounted = false → Yeoksay et
    │
    └─ build()
       └─ Return widget.child (unchanged)
```

## 🎯 Singleton Pattern (VersionControlService)

```
VersionControlService
    │
    ├─ Static _instance
    │  └─ Private singleton instance
    │
    ├─ Private constructor
    │  └─ VersionControlService._internal()
    │
    ├─ Factory constructor
    │  └─ return _instance
    │
    └─ _newVersion
       └─ Single NewVersionPlus instance
       
Usage:
VersionControlService()  → Always returns same instance
VersionControlService()  → Memory efficient & consistent
```

---

## 📌 Önemli Noktalar

1. **Async Operations** - Tüm network işlemleri async
2. **Mounted Check** - Widget build edildikten sonra kontrol
3. **Error Handling** - Try-catch ile korunmış
4. **Silent Failures** - Hata durumunda sessiz devam
5. **User Friendly** - Bottom sheet modern ve kullanıcı dostu
6. **Flexible** - Manuel ve otomatik her iki mod destek

---

## 🔐 Security

- ✅ HTTPS kullanılır (App Store/Play Store)
- ✅ Package validation yapılır
- ✅ Null safety kontrolleri
- ✅ Exception handling
- ✅ Platform-specific verification
