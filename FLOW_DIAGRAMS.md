# 📊 Notification & Payment Flow Diagrams

## 🔔 Notification Flow

### **1. User Payment → Admin Notification**

```
┌─────────────┐
│    USER     │
│  (Warga)    │
└──────┬──────┘
       │
       │ 1. Select iuran + months
       │ 2. Upload payment proof
       │ 3. Tap "Bayar Sekarang"
       │
       ▼
┌─────────────────────────────────────┐
│  _processPayment()                  │
│  - Create transactions in Firestore │
│  - Call sendNotification()          │
└──────┬──────────────────────────────┘
       │
       │ 4. Create notification doc
       │
       ▼
┌─────────────────────────────────────┐
│  Firestore                          │
│  - transaksi collection (3 docs)    │
│  - notifications collection (1 doc) │
└──────┬──────────────────────────────┘
       │
       │ 5. Trigger local notification
       │
       ▼
┌─────────────────────────────────────┐
│  NotificationService                │
│  - showNotification()               │
│  - Vibrate + Sound                  │
└──────┬──────────────────────────────┘
       │
       │ 6. Display notification
       │
       ▼
┌─────────────┐
│    ADMIN    │
│ (Bendahara) │ 📱 "Pembayaran Baru"
└─────────────┘    "John Doe membayar..."
```

---

### **2. Admin Approval → User Notification**

```
┌─────────────┐
│    ADMIN    │
│ (Bendahara) │
└──────┬──────┘
       │
       │ 1. Review payment
       │ 2. Tap "Setujui" or "Tolak"
       │
       ▼
┌─────────────────────────────────────┐
│  updateStatusTransaksi()            │
│  - Update status to 'sukses'/'gagal'│
│  - Call sendNotification()          │
└──────┬──────────────────────────────┘
       │
       │ 3. Create notification doc
       │
       ▼
┌─────────────────────────────────────┐
│  Firestore                          │
│  - Update transaksi status          │
│  - Create notification doc          │
└──────┬──────────────────────────────┘
       │
       │ 4. Trigger local notification
       │
       ▼
┌─────────────────────────────────────┐
│  NotificationService                │
│  - showNotification()               │
│  - Vibrate + Sound                  │
└──────┬──────────────────────────────┘
       │
       │ 5. Display notification
       │
       ▼
┌─────────────┐
│    USER     │
│  (Warga)    │ 📱 "Pembayaran Disetujui"
└─────────────┘    "Pembayaran Anda telah..."
```

---

## 📅 Month Selection Flow

### **User Selects Months for Payment**

```
┌─────────────┐
│    USER     │
│  (Warga)    │
└──────┬──────┘
       │
       │ 1. Open "Pembayaran" screen
       │
       ▼
┌─────────────────────────────────────┐
│  PembayaranScreen                   │
│  - Load all iuran                   │
│  - Load paid months per iuran       │
└──────┬──────────────────────────────┘
       │
       │ 2. Tap recurring iuran
       │
       ▼
┌─────────────────────────────────────┐
│  _showMonthPickerDialog()           │
│  - Show 12 months grid              │
│  - Highlight paid months (green)    │
│  - Allow selection of unpaid months │
└──────┬──────────────────────────────┘
       │
       │ 3. Select months (Jan, Feb, Mar)
       │ 4. Tap "Simpan"
       │
       ▼
┌─────────────────────────────────────┐
│  setState()                         │
│  - Update _selectedMonthsByIuran    │
│  - Recalculate _totalAmount         │
│  - Update UI                        │
└──────┬──────────────────────────────┘
       │
       │ 5. Upload payment proof
       │ 6. Tap "Bayar Sekarang"
       │
       ▼
┌─────────────────────────────────────┐
│  _processPayment()                  │
│  - Loop through selected months     │
│  - Create transaction per month     │
└──────┬──────────────────────────────┘
       │
       │ 7. Create 3 transactions
       │
       ▼
┌─────────────────────────────────────┐
│  Firestore: transaksi collection    │
│                                     │
│  Doc 1: Januari 2026 - Rp 100,000  │
│  Doc 2: Februari 2026 - Rp 100,000 │
│  Doc 3: Maret 2026 - Rp 100,000    │
└─────────────────────────────────────┘
```

---

## 🔄 Month Picker State Management

### **State Variables**

```
_selectedMonthsByIuran: Map<String, Set<String>>
├─ "iuran_1": {"Januari 2026", "Februari 2026"}
├─ "iuran_2": {"Maret 2026"}
└─ "iuran_3": {}

_paidMonthsByIuran: Map<String, Set<String>>
├─ "iuran_1": {"Desember 2025"}
├─ "iuran_2": {"Januari 2026", "Februari 2026"}
└─ "iuran_3": {}

_selectedIuranIds: Set<String>
├─ "iuran_1"
├─ "iuran_2"
└─ (iuran_3 not selected)
```

### **Total Amount Calculation**

```
_totalAmount getter:
  total = 0
  
  for each iuran in _selectedIuranIds:
    if iuran.isRecurring:
      selectedMonths = _selectedMonthsByIuran[iuran.id]
      total += iuran.harga × selectedMonths.length
    else:
      total += iuran.harga
  
  return total

Example:
  Iuran 1 (recurring): Rp 100,000 × 2 months = Rp 200,000
  Iuran 2 (recurring): Rp 150,000 × 1 month  = Rp 150,000
  Iuran 3 (one-time):  Rp 50,000  × 1        = Rp 50,000
  ────────────────────────────────────────────────────────
  Total:                                       Rp 400,000
```

---

## 📱 FCM Architecture

### **Current Implementation (Local Notifications)**

```
┌─────────────────────────────────────┐
│  App (Foreground/Background)        │
└──────┬──────────────────────────────┘
       │
       │ 1. Call showNotification()
       │
       ▼
┌─────────────────────────────────────┐
│  NotificationService                │
│  - _showLocalNotification()         │
└──────┬──────────────────────────────┘
       │
       │ 2. Create notification
       │
       ▼
┌─────────────────────────────────────┐
│  flutter_local_notifications        │
│  - Show in notification center      │
│  - Vibrate + Sound                  │
│  - Badge counter                    │
└──────┬──────────────────────────────┘
       │
       │ 3. Display
       │
       ▼
┌─────────────┐
│   DEVICE    │ 📱 Notification appears
└─────────────┘
```

### **Future Implementation (with Cloud Functions)**

```
┌─────────────────────────────────────┐
│  App (User pays)                    │
└──────┬──────────────────────────────┘
       │
       │ 1. Create transaction in Firestore
       │
       ▼
┌─────────────────────────────────────┐
│  Firestore                          │
│  - transaksi collection             │
└──────┬──────────────────────────────┘
       │
       │ 2. Trigger Cloud Function
       │
       ▼
┌─────────────────────────────────────┐
│  Cloud Function                     │
│  - onTransaksiCreate()              │
│  - Get admin FCM tokens             │
└──────┬──────────────────────────────┘
       │
       │ 3. Send FCM message
       │
       ▼
┌─────────────────────────────────────┐
│  Firebase Cloud Messaging           │
│  - Route to devices                 │
└──────┬──────────────────────────────┘
       │
       │ 4. Deliver to devices
       │
       ▼
┌─────────────┐
│   ADMIN     │ 📱 Push notification
│  DEVICES    │    (even if app is closed)
└─────────────┘
```

---

## 🎨 Month Picker UI States

### **Month Cell States**

```
┌─────────────────────────────────────┐
│  PAID MONTH                         │
│  ┌──────────────┐                   │
│  │   Januari    │ ✓                 │
│  │   (Green)    │                   │
│  └──────────────┘                   │
│  - Color: Green                     │
│  - Disabled: true                   │
│  - Checkmark: visible               │
│  - Tappable: false                  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  SELECTED MONTH                     │
│  ┌──────────────┐                   │
│  │   Februari   │ ✓                 │
│  │   (Blue)     │                   │
│  └──────────────┘                   │
│  - Color: Blue                      │
│  - Disabled: false                  │
│  - Checkmark: visible               │
│  - Tappable: true                   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  AVAILABLE MONTH                    │
│  ┌──────────────┐                   │
│  │    Maret     │                   │
│  │   (White)    │                   │
│  └──────────────┘                   │
│  - Color: White                     │
│  - Disabled: false                  │
│  - Checkmark: hidden                │
│  - Tappable: true                   │
└─────────────────────────────────────┘
```

---

## 📊 Data Flow Summary

### **Payment Process**

```
User Action → UI Update → State Change → Firestore Write → Notification
    ↓           ↓            ↓               ↓                ↓
Select      Update       Update          Create         Show to
months      total        selected        transactions   admin
            amount       months          + notification
```

### **Notification Process**

```
Firestore Change → Service Call → Notification Service → Device
       ↓                ↓                  ↓                ↓
Status update    sendNotification()   showNotification()  Display
(sukses/gagal)   (services.dart)      (notification_      notification
                                      service.dart)
```

---

## 🔍 Key Integration Points

### **1. User Screens ↔ Services**
```dart
// user_screens.dart
await _fs.addTransaksi(
  iuranId: iuran.id,
  userId: _currentUser!.id,
  periode: "Januari 2026",
  // ...
);

await _fs.sendNotification(
  title: "Pembayaran Baru",
  targetRole: "admin",
);
```

### **2. Services ↔ Notification Service**
```dart
// services.dart
await updateStatusTransaksi(transaksiId, 'sukses');
// Automatically calls:
await sendNotification(
  title: "Pembayaran Disetujui",
  targetRole: "warga",
);
```

### **3. Notification Service ↔ Device**
```dart
// notification_service.dart
await _localNotifications.show(
  id,
  title,
  body,
  details, // vibration, sound, badge
);
```

---

## 📈 Scalability Considerations

### **Current Limitations**
- ✅ Local notifications only (no cross-device sync)
- ✅ Manual notification triggering (no scheduled reminders)
- ✅ No notification history persistence

### **Future Enhancements**
- 🔜 Cloud Functions for FCM (cross-device notifications)
- 🔜 Scheduled notifications (deadline reminders)
- 🔜 Notification history in Firestore
- 🔜 Read/unread status tracking
- 🔜 Notification preferences per user

---

**This diagram provides a visual overview of how notifications and month selection work in the Tiara Finance app.**
