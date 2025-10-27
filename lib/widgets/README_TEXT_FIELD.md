# AppTextField Kullanım Kılavuzu

`AppTextField` widget'ı, uygulamada tutarlı bir TextField davranışı sağlamak için oluşturulmuştur. Varsayılan olarak her cümlenin ilk harfi büyük olarak yazılır.

## Temel Kullanım

```dart
import 'package:arti_capital/widgets/app_text_field.dart';

// Basit kullanım - cümle başları otomatik büyük
AppTextField(
  controller: _controller,
  labelText: 'Adınız',
  hintText: 'Adınızı girin',
)
```

## Özel Durumlar

### 1. E-posta, Şifre gibi alanlar (Büyük harf zorlaması OLMAMALI)
```dart
AppTextField(
  controller: _emailController,
  labelText: 'E-posta',
  keyboardType: TextInputType.emailAddress,
  textCapitalization: TextCapitalization.none, // Büyük harf zorlaması yok
)

AppTextField(
  controller: _passwordController,
  labelText: 'Şifre',
  obscureText: true,
  textCapitalization: TextCapitalization.none, // Büyük harf zorlaması yok
)
```

### 2. TC Kimlik, Plaka gibi alanlar (TÜM harfler büyük OLMALI)
```dart
AppTextField(
  controller: _tcController,
  labelText: 'TC Kimlik No',
  keyboardType: TextInputType.number,
  textCapitalization: TextCapitalization.characters, // Tüm harfler büyük
  maxLength: 11,
)

AppTextField(
  controller: _plateController,
  labelText: 'Plaka',
  textCapitalization: TextCapitalization.characters, // Tüm harfler büyük
)
```

### 3. Her kelimenin ilk harfi büyük
```dart
AppTextField(
  controller: _nameController,
  labelText: 'Ad Soyad',
  textCapitalization: TextCapitalization.words, // Her kelimenin ilk harfi büyük
)
```

### 4. Normal kullanım (varsayılan - cümle başları büyük)
```dart
// textCapitalization belirtmeye gerek yok, varsayılan olarak sentences
AppTextField(
  controller: _descriptionController,
  labelText: 'Açıklama',
  maxLines: 5,
)
```

## TextCapitalization Değerleri

- `TextCapitalization.none` - Büyük harf zorlaması yok (e-posta, şifre, kullanıcı adı)
- `TextCapitalization.sentences` - Her cümlenin ilk harfi büyük (VARSAYILAN)
- `TextCapitalization.words` - Her kelimenin ilk harfi büyük (ad soyad)
- `TextCapitalization.characters` - Tüm harfler büyük (TC kimlik, plaka, IBAN)

## Mevcut TextField'ları Değiştirme

Mevcut TextField kullanımlarınızı AppTextField ile değiştirin:

### Önce:
```dart
TextField(
  controller: _controller,
  decoration: InputDecoration(
    labelText: 'Açıklama',
  ),
)
```

### Sonra:
```dart
AppTextField(
  controller: _controller,
  labelText: 'Açıklama',
  // textCapitalization: TextCapitalization.sentences, // Otomatik, belirtmeye gerek yok
)
```
