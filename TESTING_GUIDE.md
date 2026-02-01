# 🧪 Quick Testing Guide: Notifications & Month Picker

## 🔔 Testing Notifications

### **Test 1: Local Notification (Easiest)**

Add this code anywhere in your app (e.g., in a button's onPressed):

```dart
import 'package:tiara_fin/notification_service.dart';

// Test notification
await NotificationService().showNotification(
  title: "🎉 Test Notification",
  body: "Notification system is working!",
  data: {'type': 'test'},
);
```

**Expected Result**:
- ✅ Notification appears in device notification center
- ✅ Phone vibrates
- ✅ Notification sound plays
- ✅ Tapping notification opens the app

---

### **Test 2: Payment Notification Flow**

**Step 1: User Makes Payment**
1. Login as a regular user (warga)
2. Go to "Pembayaran" screen
3. Select an iuran (e.g., "Iuran Kebersihan")
4. For recurring iuran: Select months (e.g., Jan, Feb, Mar)
5. Upload payment proof
6. Tap "Bayar Sekarang"

**Expected Result**:
- ✅ Admin receives notification: "💰 Pembayaran Baru"
- ✅ Notification body shows user name and amount

**Step 2: Admin Approves Payment**
1. Login as admin (bendahara)
2. Go to "Verifikasi Pembayaran" screen
3. Tap on pending payment
4. Tap "Setujui"

**Expected Result**:
- ✅ User receives notification: "✅ Pembayaran Disetujui"
- ✅ Notification body shows payment details

**Step 3: Admin Rejects Payment**
1. Same as above, but tap "Tolak"

**Expected Result**:
- ✅ User receives notification: "❌ Pembayaran Ditolak"
- ✅ Notification body shows rejection message

---

### **Test 3: FCM from Firebase Console**

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Cloud Messaging** (left sidebar)
4. Click **"Send your first message"**
5. Fill in:
   - **Notification title**: "Test from Firebase"
   - **Notification text**: "This is a test notification"
6. Click **"Next"**
7. Select **"Topic"** and enter: `admin` or `warga`
8. Click **"Next"** → **"Review"** → **"Publish"**

**Expected Result**:
- ✅ All devices subscribed to the topic receive the notification
- ✅ Notification appears even when app is closed

---

### **Test 4: Topic Subscription**

Add this code after successful login:

```dart
// In auth_screens.dart or wherever you handle login
if (user.role == 'admin' || user.role == 'bendahara') {
  await NotificationService().subscribeToTopic('admin');
  print('✅ Subscribed to admin topic');
} else {
  await NotificationService().subscribeToTopic('warga');
  print('✅ Subscribed to warga topic');
}
```

Add this code on logout:

```dart
// On logout
await NotificationService().unsubscribeFromTopic('admin');
await NotificationService().unsubscribeFromTopic('warga');
print('❌ Unsubscribed from all topics');
```

**Expected Result**:
- ✅ Console shows subscription messages
- ✅ User receives notifications for their role

---

### **Test 5: Get FCM Token**

Add this code to see the device's FCM token:

```dart
String? token = await NotificationService().getToken();
print('📱 FCM Token: $token');

// Optional: Save to Firestore for targeted notifications
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'fcm_token': token});
```

**Expected Result**:
- ✅ Console shows a long token string
- ✅ Token is saved to Firestore (if you added the optional code)

---

## 📅 Testing Month Picker

### **Test 1: Select Months for Recurring Iuran**

1. Login as a regular user
2. Go to "Pembayaran" screen
3. Find a **recurring iuran** (has blue badge: "Bulanan" or "Tahunan")
4. Tap on the iuran card

**Expected Result**:
- ✅ Month picker dialog appears
- ✅ Shows 12 months (Jan-Dec)
- ✅ Current year is displayed

5. Tap on multiple months (e.g., January, February, March)

**Expected Result**:
- ✅ Selected months turn blue with checkmark
- ✅ Can select/deselect months

6. Tap "Simpan"

**Expected Result**:
- ✅ Dialog closes
- ✅ Iuran card shows "3 bulan dipilih"
- ✅ Total amount updates (e.g., Rp 300,000 for 3 months × Rp 100,000)

---

### **Test 2: Paid Months are Disabled**

**Setup**: First, make a payment for January

1. Select January in month picker
2. Upload payment proof
3. Pay and get admin approval

**Test**: Now try to select January again

1. Tap on the same iuran
2. Month picker opens

**Expected Result**:
- ✅ January is **green** and **disabled**
- ✅ Cannot select January (already paid)
- ✅ Info banner shows: "1 bulan sudah dibayar"

---

### **Test 3: One-Time Iuran (No Month Picker)**

1. Find a **one-time iuran** (has orange badge: "Sekali")
2. Tap on the iuran card

**Expected Result**:
- ✅ No month picker dialog
- ✅ Iuran is simply selected (checkmark appears)
- ✅ Total amount is the iuran price (not multiplied)

---

### **Test 4: Payment with Multiple Months**

1. Select a recurring iuran
2. Pick 3 months (e.g., Jan, Feb, Mar)
3. Upload payment proof
4. Tap "Bayar Sekarang"

**Expected Result**:
- ✅ Success message appears
- ✅ 3 separate transactions created in Firestore
- ✅ Each transaction has:
  - `periode`: "Januari 2026", "Februari 2026", "Maret 2026"
  - `deskripsi`: "Bayar: Iuran Kebersihan (Januari)", etc.
  - `uang`: Same amount for each
  - `status`: "menunggu"

5. Check Firestore:
   - Go to Firebase Console → Firestore
   - Open `transaksi` collection
   - Verify 3 documents were created

---

## 🐛 Troubleshooting

### **Notifications Not Appearing**

**Problem**: No notification shows up

**Solutions**:
1. Check app permissions:
   - Settings → Apps → Tiara Finance → Notifications → **Enable**
2. Check Android version:
   - Android 13+ requires `POST_NOTIFICATIONS` permission (already added)
3. Check logs:
   ```bash
   flutter logs
   ```
   Look for: `✅ User granted notification permission`

---

### **Vibration Not Working**

**Problem**: No vibration on notification

**Solutions**:
1. Check device settings:
   - Settings → Sound & vibration → **Enable vibration**
2. Check Do Not Disturb mode:
   - Disable DND temporarily
3. Verify permission in AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.VIBRATE" />
   ```

---

### **Month Picker Not Opening**

**Problem**: Tapping iuran doesn't open month picker

**Solutions**:
1. Check if iuran is recurring:
   - Only recurring iuran (bulanan, tahunan) have month picker
   - One-time iuran (sekali) just toggle selection
2. Check if iuran is already paid:
   - Paid iuran are disabled (can't select)
3. Check console for errors:
   ```bash
   flutter logs
   ```

---

### **FCM Token is Null**

**Problem**: `getToken()` returns null

**Solutions**:
1. Check Firebase initialization:
   - Ensure `Firebase.initializeApp()` is called in `main.dart`
2. Check internet connection:
   - FCM requires internet to get token
3. Check google-services.json:
   - Ensure file exists in `android/app/`
4. Rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### **Paid Months Not Showing as Green**

**Problem**: Already paid months are not disabled

**Solutions**:
1. Check Firestore data:
   - Ensure transactions have `periode` field (e.g., "Januari 2026")
   - Ensure transactions have `status: "sukses"`
2. Check `_loadPaidMonths()` method:
   - Should query transactions with matching iuran_id and user_id
3. Restart the app:
   - Sometimes state doesn't update immediately

---

## 📊 Expected Firestore Structure

### **Transaction Document** (after payment)
```json
{
  "iuran_id": "abc123",
  "user_id": "user456",
  "user_name": "John Doe",
  "uang": 100000,
  "tipe": "pemasukan",
  "deskripsi": "Bayar: Iuran Kebersihan (Januari)",
  "timestamp": "2026-01-19T10:30:00Z",
  "status": "menunggu",
  "bukti_gambar": "https://...",
  "periode": "Januari 2026",
  "metode": "va"
}
```

### **Notification Document**
```json
{
  "title": "Pembayaran Baru",
  "body": "John Doe mengirim pembayaran 1 jenis iuran. Total: Rp 300.000",
  "type": "payment",
  "target_role": "admin",
  "timestamp": "2026-01-19T10:30:00Z",
  "is_read": false
}
```

---

## ✅ Quick Checklist

Before testing, ensure:
- [ ] `flutter pub get` completed successfully
- [ ] App builds without errors
- [ ] Firebase is initialized
- [ ] google-services.json exists
- [ ] Notification permissions granted
- [ ] Internet connection active
- [ ] At least one recurring iuran exists in Firestore
- [ ] At least one user and one admin account exist

---

## 🎯 Success Criteria

**Notifications**:
- ✅ Local notifications appear
- ✅ Vibration works
- ✅ Sound plays
- ✅ Tapping notification opens app
- ✅ Admin receives payment notifications
- ✅ User receives approval/rejection notifications

**Month Picker**:
- ✅ Dialog opens for recurring iuran
- ✅ Can select multiple months
- ✅ Paid months are disabled
- ✅ Total amount updates correctly
- ✅ Individual transactions created per month
- ✅ Transactions have correct `periode` field

---

## 🚀 Next: Production Testing

Once local testing passes:
1. Test on physical device (not emulator)
2. Test with app in background
3. Test with app completely closed
4. Test with different Android versions (11, 12, 13, 14)
5. Test with different launchers (Samsung, Xiaomi, Stock)
6. Test FCM from Firebase Console
7. Test with Cloud Functions (if implemented)

---

**Happy Testing! 🎉**

If you encounter any issues not covered here, check the logs with `flutter logs` and refer to `FCM_SETUP_GUIDE.md` for detailed setup instructions.
