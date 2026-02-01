# Setup Firebase Cloud Messaging (FCM) - Panduan Lengkap

## ✅ Yang Sudah Diimplementasikan:

### 1. **Dependencies**
```yaml
# pubspec.yaml
firebase_messaging: ^15.2.10
flutter_local_notifications: ^17.2.3
```

### 2. **Notification Service** (`lib/notification_service.dart`)
- ✅ FCM initialization
- ✅ Local notifications dengan popup
- ✅ Badge counter
- ✅ Vibration
- ✅ Sound notification
- ✅ Background message handler
- ✅ Foreground message handler
- ✅ Notification tap handler

### 3. **Main.dart Integration**
- ✅ Background handler registered
- ✅ Notification service initialized on app start

## 📱 Konfigurasi Android (WAJIB)

### 1. Update `android/app/src/main/AndroidManifest.xml`

Tambahkan permissions dan meta-data:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application
        android:label="Tiara Finance"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:showWhenLocked="true"
            android:turnScreenOn="true">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- FCM Intent Filter -->
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>

        <!-- FCM Service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="tiara_finance_channel" />
            
        <!-- Default notification icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
            
        <!-- Default notification color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 2. Create `android/app/src/main/res/values/colors.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#6366F1</color>
</resources>
```

### 3. Update `android/app/build.gradle`

Pastikan minSdkVersion minimal 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimal untuk FCM
        targetSdkVersion 34
    }
}
```

## 🔔 Cara Menggunakan

### 1. **Kirim Notifikasi dari Code**

```dart
import 'package:tiara_fin/notification_service.dart';

// Show local notification
await NotificationService().showNotification(
  title: "Pembayaran Baru",
  body: "Aceva mengirim pembayaran Rp 300.000",
  data: {
    'type': 'payment',
    'user_id': 'user123',
  },
);
```

### 2. **Subscribe ke Topic** (untuk broadcast notification)

```dart
// Subscribe saat login
await NotificationService().subscribeToTopic('admin');
await NotificationService().subscribeToTopic('warga');

// Unsubscribe saat logout
await NotificationService().unsubscribeFromTopic('admin');
```

### 3. **Get FCM Token** (untuk kirim notifikasi ke specific user)

```dart
String? token = await NotificationService().getToken();
print('FCM Token: $token');
// Save token ke Firestore untuk kirim notifikasi personal
```

## 🚀 Testing Notification

### Test 1: Local Notification
```dart
// Di mana saja dalam app
NotificationService().showNotification(
  title: "Test Notification",
  body: "Ini adalah test notification",
);
```

### Test 2: FCM dari Firebase Console

1. Buka Firebase Console → Cloud Messaging
2. Klik "Send your first message"
3. Masukkan:
   - **Title**: "Test FCM"
   - **Body**: "Notification dari Firebase"
   - **Target**: Topic "admin" atau "warga"
4. Send

### Test 3: Programmatic FCM (dari backend/Cloud Functions)

```javascript
// Cloud Function example
const admin = require('firebase-admin');

await admin.messaging().send({
  notification: {
    title: 'Pembayaran Baru',
    body: 'Aceva membayar Rp 300.000'
  },
  data: {
    type: 'payment',
    amount: '300000'
  },
  topic: 'admin'
});
```

## 📊 Notification Flow

### User Bayar → Admin Notified:
```
1. User tap "Bayar Sekarang"
2. services.dart: sendNotification(targetRole: "admin")
3. Firestore: Create notification document
4. Cloud Function (optional): Send FCM to topic "admin"
5. Admin device: Receive push notification
6. Admin tap notification → Navigate to verification screen
```

### Admin Approve → User Notified:
```
1. Admin tap "Approve"
2. services.dart: updateStatusTransaksi() → sendNotification(targetRole: "warga")
3. Firestore: Create notification document
4. Cloud Function (optional): Send FCM to specific user token
5. User device: Receive push notification
6. User tap notification → Navigate to transaction history
```

## 🎨 Notification Features

### ✅ Implemented:
- [x] Push notification di luar app
- [x] Notification center integration
- [x] Vibration
- [x] Sound
- [x] Badge counter (in NotificationService)
- [x] Big text style (untuk body panjang)
- [x] Tap to open app
- [x] Background handler
- [x] Foreground handler

### 🔜 To Be Implemented:
- [ ] Navigate to specific screen on tap
- [ ] Notification history screen
- [ ] Mark as read functionality
- [ ] Clear all notifications
- [ ] Scheduled notifications (reminder deadline)

## 🔧 Troubleshooting

### Notification tidak muncul?
1. Check permission: `Settings → Apps → Tiara Finance → Notifications`
2. Check FCM token: `print(await NotificationService().getToken())`
3. Check Logcat: `flutter logs` untuk lihat error

### Vibration tidak bekerja?
- Pastikan permission `VIBRATE` ada di AndroidManifest.xml
- Check device settings: Sound & vibration

### Badge counter tidak muncul?
- Badge counter di Android tergantung launcher
- Beberapa launcher (Samsung, Xiaomi) support, beberapa tidak
- Untuk iOS, badge otomatis work

## 📝 Next Steps

1. **Implement Navigation on Tap**
   - Parse notification data
   - Navigate to specific screen (payment detail, transaction, etc)

2. **Notification History Screen**
   - Show all notifications
   - Mark as read
   - Delete notification

3. **Scheduled Notifications**
   - Reminder H-7, H-3, H-1 sebelum deadline
   - Menggunakan Cloud Functions + Firestore triggers

4. **Rich Notifications**
   - Image dalam notification
   - Action buttons (Approve/Reject langsung dari notif)

## 🎯 Integration dengan Existing Code

### Update services.dart:

```dart
// Saat kirim notifikasi, juga trigger FCM
Future<void> sendNotification({...}) async {
  // 1. Save to Firestore (existing)
  await _db.collection('notifications').add({...});
  
  // 2. Send FCM push notification (NEW)
  await NotificationService().showNotification(
    title: title,
    body: body,
    data: {'type': type, 'target': targetRole},
  );
  
  // 3. Or send via topic
  // This will be handled by Cloud Function
}
```

### Subscribe on Login:

```dart
// auth_screens.dart - after successful login
if (user.role == 'admin') {
  await NotificationService().subscribeToTopic('admin');
} else {
  await NotificationService().subscribeToTopic('warga');
}
```

### Unsubscribe on Logout:

```dart
// Saat logout
await NotificationService().unsubscribeFromTopic('admin');
await NotificationService().unsubscribeFromTopic('warga');
```

## ✅ Checklist Setup

- [ ] Update AndroidManifest.xml
- [ ] Create colors.xml
- [ ] Update build.gradle (minSdkVersion 21)
- [ ] Run `flutter pub get`
- [ ] Test local notification
- [ ] Test FCM from Firebase Console
- [ ] Subscribe to topics on login
- [ ] Unsubscribe on logout
- [ ] Implement navigation on tap
- [ ] Create notification history screen
