# 🔔 Fitur Notifikasi Lengkap

## ✅ Yang Sudah Diimplementasikan

### **1. Badge Counter di Icon Lonceng** 🔴
- **Lokasi**: Header halaman utama (User & Admin)
- **Fitur**:
  - Menampilkan jumlah notifikasi yang belum dibaca
  - Update real-time menggunakan `StreamBuilder`
  - Tampil angka 1-9, atau "9+" jika lebih dari 9
  - Badge merah bulat di pojok kanan atas icon lonceng
  - Otomatis hilang jika semua notifikasi sudah dibaca

### **2. Halaman Notifikasi** 📱
- **Akses**: Tap icon lonceng di header
- **Fitur**:
  - List semua notifikasi (max 50 terbaru)
  - Filter otomatis berdasarkan role (admin/warga)
  - Sorting: Terbaru di atas
  - Empty state jika belum ada notifikasi

### **3. Notifikasi yang Bisa Diklik** 👆
- **Fitur**:
  - Tap notifikasi → Muncul dialog detail
  - Otomatis mark as read saat diklik
  - Visual feedback:
    - **Belum dibaca**: Background biru muda + dot merah + bold text
    - **Sudah dibaca**: Background putih + normal text
  - Icon chevron kanan untuk indikasi bisa diklik

### **4. Dialog Detail Notifikasi** 💬
- **Konten**:
  - Icon sesuai tipe (payment/alert/info)
  - Judul notifikasi
  - Body/isi lengkap
  - Timestamp (tanggal & waktu)
  - Tombol "Tutup"

### **5. Tipe Notifikasi** 🎨
- **Payment** (Hijau):
  - Icon: `Icons.payment`
  - Untuk notifikasi pembayaran
  
- **Alert** (Merah):
  - Icon: `Icons.warning_amber_rounded`
  - Untuk notifikasi penting/peringatan
  
- **Info** (Biru):
  - Icon: `Icons.info_outline`
  - Untuk notifikasi informasi umum

---

## 📊 Flow Notifikasi

### **User Bayar → Admin Dapat Notifikasi**

```
1. User upload bukti pembayaran
2. services.dart: sendNotification(targetRole: "admin")
3. Firestore: Create notification document
   {
     title: "Pembayaran Baru",
     body: "John Doe membayar...",
     type: "payment",
     target_role: "admin",
     is_read: false,
     timestamp: now
   }
4. StreamBuilder di admin screen: Detect new notification
5. Badge counter update: 1 → 2 (jika ada 1 notif sebelumnya)
6. Admin tap icon lonceng → Lihat list notifikasi
7. Admin tap notifikasi → Dialog detail muncul
8. Otomatis mark as read
9. Badge counter update: 2 → 1
```

### **Admin Approve → User Dapat Notifikasi**

```
1. Admin approve pembayaran
2. services.dart: updateStatusTransaksi() → sendNotification(targetRole: "warga")
3. Firestore: Create notification document
4. StreamBuilder di user screen: Detect new notification
5. Badge counter update
6. User tap icon lonceng → Lihat notifikasi
7. User tap notifikasi → Dialog detail
8. Mark as read
```

---

## 🎨 Visual Design

### **Badge Counter**
```
┌─────────────┐
│     🔔      │ ← Icon lonceng
│         🔴3 │ ← Badge merah dengan angka
└─────────────┘
```

### **Notifikasi Belum Dibaca**
```
┌─────────────────────────────────────────┐
│ 💰  Pembayaran Baru              🔴     │ ← Dot merah
│     John Doe membayar Rp 300.000        │
│     2 jam yang lalu                  ›  │ ← Chevron
└─────────────────────────────────────────┘
Background: Biru muda
Border kiri: Hijau (payment)
```

### **Notifikasi Sudah Dibaca**
```
┌─────────────────────────────────────────┐
│ 💰  Pembayaran Baru                     │
│     John Doe membayar Rp 300.000        │
│     2 jam yang lalu                  ›  │
└─────────────────────────────────────────┘
Background: Putih
Border kiri: Hijau (payment)
Font: Normal (tidak bold)
```

### **Dialog Detail**
```
┌─────────────────────────────────────────┐
│ 💰  Pembayaran Baru                     │
│                                         │
│ John Doe mengirim pembayaran 1 jenis    │
│ iuran. Total: Rp 300.000                │
│                                         │
│ 🕐 20 Jan 2026, 14:30                   │
│                                         │
│                          [Tutup]        │
└─────────────────────────────────────────┘
```

---

## 💻 Kode yang Diubah/Ditambahkan

### **1. notification_screen.dart** (Enhanced)

#### **Fitur Baru**:
- `_showNotificationDetail()` - Dialog detail notifikasi
- `_getNotificationIcon()` - Helper untuk icon berdasarkan tipe
- Badge "X baru" di AppBar
- InkWell wrapper untuk notifikasi (bisa diklik)
- Visual feedback (background biru untuk unread)
- Dot merah untuk notifikasi belum dibaca
- Chevron icon di kanan

#### **Kode Penting**:
```dart
// Mark as read saat diklik
void _showNotificationDetail(NotificationModel notif) {
  _fs.markNotificationAsRead(notif.id);
  // ... show dialog
}

// Badge di AppBar
StreamBuilder<List<NotificationModel>>(
  stream: _fs.getNotifications(_userRole),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data!.where((n) => !n.isRead).length;
    // ... tampilkan badge
  },
)

// Notifikasi bisa diklik
InkWell(
  onTap: () => _showNotificationDetail(notif),
  child: Container(
    color: notif.isRead ? Colors.white : Colors.blue.shade50,
    // ...
  ),
)
```

### **2. services.dart** (New Method)

#### **Method Baru**:
```dart
Future<void> markNotificationAsRead(String notificationId) async {
  await _db.collection('notifications').doc(notificationId).update({
    'is_read': true,
  });
}
```

### **3. user_screens.dart** (Badge Counter)

#### **Icon Lonceng dengan Badge**:
```dart
StreamBuilder<List<NotificationModel>>(
  stream: _fs.getNotifications(_currentUser?.role ?? 'warga'),
  builder: (context, snapshot) {
    final unreadCount = snapshot.hasData 
      ? snapshot.data!.where((n) => !n.isRead).length 
      : 0;
    
    return Stack(
      children: [
        Container(/* Icon lonceng */),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              /* Badge merah dengan angka */
              child: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            ),
          ),
      ],
    );
  },
)
```

### **4. admin_screens.dart** (Badge Counter)

Sama seperti user_screens.dart, tapi dengan `stream: _fs.getNotifications('admin')`

---

## 🧪 Testing

### **Test 1: Badge Counter**
1. Login sebagai user
2. **Expected**: Icon lonceng tanpa badge (jika belum ada notif)
3. Admin approve pembayaran user lain
4. **Expected**: Badge muncul dengan angka 1
5. Tap icon lonceng → Lihat notifikasi
6. Tap notifikasi → Dialog muncul
7. Close dialog
8. **Expected**: Badge hilang (notif sudah dibaca)

### **Test 2: Notifikasi Bisa Diklik**
1. Buka halaman notifikasi
2. **Expected**: Notifikasi belum dibaca punya background biru + dot merah
3. Tap notifikasi
4. **Expected**: Dialog detail muncul
5. Close dialog
6. **Expected**: Background jadi putih (sudah dibaca)
7. **Expected**: Dot merah hilang

### **Test 3: Multiple Notifications**
1. Buat 5 pembayaran dari user berbeda
2. Login sebagai admin
3. **Expected**: Badge menampilkan "5"
4. Tap icon lonceng
5. **Expected**: AppBar menampilkan "5 baru"
6. Tap 3 notifikasi
7. **Expected**: Badge update jadi "2"
8. **Expected**: AppBar update jadi "2 baru"

### **Test 4: Badge 9+**
1. Buat 15 pembayaran
2. **Expected**: Badge menampilkan "9+"
3. Baca 10 notifikasi
4. **Expected**: Badge update jadi "5"

---

## 📱 Firestore Structure

### **Notification Document**
```json
{
  "title": "Pembayaran Baru",
  "body": "John Doe mengirim pembayaran 1 jenis iuran. Total: Rp 300.000",
  "type": "payment",
  "target_role": "admin",
  "is_read": false,
  "timestamp": Timestamp(2026, 1, 20, 14, 30, 0)
}
```

### **Fields**:
- `title` (string): Judul notifikasi
- `body` (string): Isi lengkap notifikasi
- `type` (string): "payment", "alert", atau "info"
- `target_role` (string): "admin", "warga", atau "all"
- `is_read` (boolean): Status baca
- `timestamp` (Timestamp): Waktu notifikasi dibuat

---

## 🎯 Fitur Tambahan yang Bisa Diimplementasikan

### **1. Push Notification** (Butuh Cloud Functions)
- Kirim FCM saat notifikasi baru dibuat
- Notifikasi muncul meski app tertutup
- Tap notifikasi → Buka app → Langsung ke detail

### **2. Mark All as Read**
- Tombol di AppBar halaman notifikasi
- Tandai semua notifikasi sebagai sudah dibaca
- Badge langsung jadi 0

### **3. Delete Notification**
- Swipe to delete
- Atau tombol delete di dialog detail
- Hapus dari Firestore

### **4. Filter Notifikasi**
- Filter by type (payment/alert/info)
- Filter by date (hari ini/minggu ini/bulan ini)
- Filter by read status (belum dibaca/sudah dibaca)

### **5. Notification Settings**
- User bisa pilih tipe notifikasi yang mau diterima
- Enable/disable notifikasi per kategori
- Simpan preferensi di Firestore

---

## ✅ Summary

**Yang Sudah Berfungsi**:
- ✅ Badge counter real-time di icon lonceng
- ✅ Halaman notifikasi dengan list
- ✅ Notifikasi bisa diklik
- ✅ Dialog detail notifikasi
- ✅ Mark as read otomatis
- ✅ Visual feedback (biru untuk unread)
- ✅ Dot merah untuk notifikasi baru
- ✅ Badge "X baru" di AppBar
- ✅ Filter by role (admin/warga)
- ✅ Tipe notifikasi dengan icon & warna berbeda

**Catatan**:
- Popup notifikasi (local notification) sudah diimplementasikan di `NotificationService`
- Untuk testing popup, perlu trigger dari `services.dart` saat create notification
- Badge counter update otomatis karena menggunakan `StreamBuilder`

---

**Update Date**: 20 Januari 2026  
**Status**: ✅ Fully Implemented & Ready for Testing
