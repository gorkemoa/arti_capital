# 🔔 Firebase Cloud Messaging - User ID Bazlı Topic Bildirimleri

## 📋 Genel Bakış

Push bildirimler artık her kullanıcı için özel topic'ler kullanılarak gönderiliyor. Her kullanıcı kendi user ID'sine göre oluşturulan bir topic'e abone oluyor.

## 🎯 Topic Yapısı

- **Format**: `user_{userId}`
- **Örnek**: Kullanıcı ID'si 123 ise → `user_123`

## 🔄 Otomatik Topic Yönetimi

### Login Sırasında
```dart
// Kullanıcı giriş yaptığında otomatik olarak kendi topic'ine abone olur
await NotificationsService.subscribeToUserTopic(userId);
```

### Logout Sırasında
```dart
// Kullanıcı çıkış yaptığında otomatik olarak topic'ten çıkar
await NotificationsService.unsubscribeFromUserTopic(userId);
```

### Uygulama Başlangıcında
```dart
// Uygulama her başladığında token alınır ve kullanıcı topic'e abone olur
await NotificationsService.sendTokenToServer();
```

## 📱 Kullanım Senaryoları

### 1. Tek Kullanıcıya Bildirim Gönderme

Firebase Console veya Backend'den:

```json
{
  "message": {
    "topic": "user_123",
    "notification": {
      "title": "Yeni Randevu",
      "body": "15:00'te randevunuz var"
    },
    "data": {
      "type": "appointment",
      "appointmentId": "456"
    },
    "apns": {
      "payload": {
        "aps": {
          "alert": {
            "title": "Yeni Randevu",
            "body": "15:00'te randevunuz var"
          },
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

### 2. Birden Fazla Kullanıcıya Bildirim

Topic condition kullanarak:

```json
{
  "message": {
    "condition": "'user_123' in topics || 'user_456' in topics || 'user_789' in topics",
    "notification": {
      "title": "Grup Bildirimi",
      "body": "Tüm şirket ortaklarına mesaj"
    }
  }
}
```

### 3. Backend'den Bildirim Gönderme (Node.js Örneği)

```javascript
const admin = require('firebase-admin');

// Tek kullanıcıya gönder
async function sendToUser(userId, title, body, data = {}) {
  const message = {
    notification: {
      title: title,
      body: body
    },
    data: data,
    topic: `user_${userId}`,
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body
          },
          sound: 'default',
          badge: 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Bildirim gönderildi:', response);
    return response;
  } catch (error) {
    console.error('Bildirim hatası:', error);
    throw error;
  }
}

// Kullanım
await sendToUser(123, 'Yeni Mesaj', 'Mesajınız var', {
  type: 'message',
  messageId: '789'
});
```

### 4. Backend'den Bildirim Gönderme (PHP Örneği)

```php
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

function sendToUser($messaging, $userId, $title, $body, $data = []) {
    $topic = "user_" . $userId;
    
    $message = CloudMessage::withTarget('topic', $topic)
        ->withNotification(Notification::create($title, $body))
        ->withData($data)
        ->withApnsConfig([
            'payload' => [
                'aps' => [
                    'alert' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'sound' => 'default',
                    'badge' => 1,
                ],
            ],
        ]);
    
    try {
        $result = $messaging->send($message);
        return $result;
    } catch (\Exception $e) {
        error_log("Bildirim hatası: " . $e->getMessage());
        throw $e;
    }
}

// Kullanım
sendToUser($messaging, 123, 'Yeni Randevu', '15:00 randevunuz var', [
    'type' => 'appointment',
    'appointmentId' => '456'
]);
```

## 🔧 Manuel Topic Yönetimi

Gerektiğinde manuel olarak topic'lere abone olabilir veya çıkabilirsiniz:

```dart
// Abone ol
await NotificationsService.subscribeToUserTopic(userId);

// Abonelikten çık
await NotificationsService.unsubscribeFromUserTopic(userId);
```

## 📊 Avantajları

1. **Güvenlik**: Her kullanıcı sadece kendi bildirimleri alır
2. **Ölçeklenebilirlik**: Milyonlarca kullanıcı için çalışır
3. **Basitlik**: Backend'de karmaşık token yönetimi gerekmez
4. **Esneklik**: Grup bildirimleri için condition kullanılabilir
5. **Offline Destek**: Kullanıcı offline bile olsa bildirim kuyruğa alınır

## 🚨 Önemli Notlar

1. **Topic İsimleri**: 
   - Sadece harfler, sayılar ve `_`, `-`, `.` karakterleri kullanılabilir
   - Maximum 900 karaktere kadar
   - Bizim format: `user_{userId}`

2. **Subscription Limitleri**:
   - Bir cihaz maximum 2000 topic'e abone olabilir
   - Topic subscription süresi yok (kalıcı)

3. **Mesaj Limitleri**:
   - FCM mesaj boyutu max 4KB
   - Saniyede ~500 mesaj/topic gönderilebilir

4. **Gecikme**:
   - Topic subscription 1-2 dakika sürebilir
   - Login sonrası hemen bildirim gönderilirse gelmeyebilir
   - Production'da genellikle anlık çalışır

## 🧪 Test Etme

### Firebase Console'dan Test:

1. Firebase Console → Cloud Messaging
2. "Send test message" yerine "New campaign" seçin
3. Notification başlık ve body girin
4. Target → Topic seçin
5. Topic name: `user_123` (test user ID)
6. Send

### Curl ile Test:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/articapital/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "topic": "user_123",
      "notification": {
        "title": "Test Bildirimi",
        "body": "Bu bir test mesajıdır"
      },
      "apns": {
        "payload": {
          "aps": {
            "alert": {
              "title": "Test Bildirimi",
              "body": "Bu bir test mesajıdır"
            },
            "sound": "default"
          }
        }
      }
    }
  }'
```

## 📱 Debug Logları

Uygulamada topic subscription loglarını görmek için:

```
[FCM_TOPIC] User topic'e abone olundu: user_123
[FCM_TOPIC] User topic'den çıkıldı: user_123
[FCM_TOKEN] FCM Token: [token]
```

## 🔗 İlgili Dosyalar

- `lib/services/notifications_service.dart` - Topic subscription metodları
- `lib/services/auth_service.dart` - Login/logout sırasında topic yönetimi
- `ios/Runner/AppDelegate.swift` - Native iOS bildirim handling

## 📖 Firebase Dokümantasyonu

- [FCM Topic Messaging](https://firebase.google.com/docs/cloud-messaging/android/topic-messaging)
- [FCM Server Reference](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [FCM Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)
