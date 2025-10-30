/// VERSION_CONTROL_INTEGRATION.md
/// 
/// Bu dosya mevcut settings_view.dart dosyasına versiyon kontrolü entegrasyonunun
/// nasıl yapılacağını göstermektedir.

# Settings View'e Versiyon Kontrolü Entegrasyonu

## Adım 1: Import Ekleyin

Mevcut settings_view.dart dosyasının başına şu import'ları ekleyin:

```dart
import 'package:arti_capital/services/version_control_service.dart';
import 'package:arti_capital/widgets/update_bottom_sheet.dart';
```

## Adım 2: State'e Alan Ekleyin

Settings sayfası StatefulWidget ise, state sınıfına şu alanı ekleyin:

```dart
bool _isCheckingVersion = false;
```

## Adım 3: Versiyon Kontrol Fonksiyonu Ekleyin

Settings view'in state sınıfına şu metodu ekleyin:

```dart
Future<void> _checkVersionManually() async {
  setState(() => _isCheckingVersion = true);

  try {
    final status = await VersionControlService().getVersionStatus();

    if (!mounted) return;

    if (status != null && status.canUpdate) {
      await UpdateBottomSheet.show(
        context,
        versionStatus: status,
        isMandatory: false,
      );
    } else if (status != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uygulamanız güncel'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('Version check error: $e');
  } finally {
    if (mounted) {
      setState(() => _isCheckingVersion = false);
    }
  }
}
```

## Adım 4: UI'da ListTile Ekleyin

Ayarlar sayfasında uygun bir yere şu ListTile'ı ekleyin:

```dart
ListTile(
  leading: Icon(Icons.system_update),
  title: const Text('Güncellemeleri Kontrol Et'),
  subtitle: const Text('Yeni versiyon kontrol et'),
  trailing: _isCheckingVersion
      ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: _isCheckingVersion ? null : _checkVersionManually,
  enabled: !_isCheckingVersion,
)
```

## Adım 5: Versiyon Bilgisi Gösterme (Opsiyonel)

Ayarlar sayfasında mevcut versiyon bilgisini göstermek için:

```dart
ListTile(
  leading: Icon(Icons.info_outline),
  title: const Text('Versiyon'),
  subtitle: const Text('1.0.0 (Build 1)'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
)
```

## Örnek Entegrasyon

Aşağıda, bir SettingsView'in ayarları bölümünün nasıl görüneceğini gösteren örnek bulunmaktadır:

```dart
class _SettingsViewState extends State<SettingsView> {
  bool _isCheckingVersion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          // ... diğer ayarlar ...
          
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16),
            child: Text('Hakkında', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          ListTile(
            leading: Icon(Icons.system_update),
            title: const Text('Güncellemeleri Kontrol Et'),
            trailing: _isCheckingVersion
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isCheckingVersion ? null : _checkVersionManually,
          ),
          
          ListTile(
            leading: Icon(Icons.info_outline),
            title: const Text('Versiyon'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVersionManually() async {
    setState(() => _isCheckingVersion = true);

    try {
      final status = await VersionControlService().getVersionStatus();

      if (!mounted) return;

      if (status != null && status.canUpdate) {
        await UpdateBottomSheet.show(context, versionStatus: status);
      } else if (status != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uygulamanız güncel'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Version check error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingVersion = false);
      }
    }
  }
}
```

## Notlar

- Versiyon kontrolü internet bağlantısı gerektirir
- İlk kez çalıştırırken biraz zaman alabilir
- Bottom sheet otomatik olarak App Store/Play Store linki açar
- Zorunlu güncelleme için `isMandatory: true` parametresini kullanın

## Sorun Giderme

**Versiyon kontrolü hata veriyorsa:**
1. Internet bağlantısını kontrol edin
2. App ID'lerinizin doğru olduğundan emin olun
3. Logs'ta ayrıntılı hata mesajını kontrol edin

**Bottom sheet gösterilmiyorsa:**
1. `status.canUpdate` değerini kontrol edin
2. `status` nesnesi null olup olmadığını kontrol edin
3. Context'in valid olduğundan emin olun
