# Fitur Pemilihan Bulan Spesifik & Notifikasi - Dokumentasi

## 🎯 Ringkasan Fitur

### ✅ Sudah Diimplementasikan:

#### 1. **Pemilihan Bulan Spesifik untuk Iuran Rutin**
User bisa memilih bulan mana saja yang ingin dibayar untuk iuran rutin (bulanan/tahunan).

**Cara Kerja:**
- User tap pada iuran rutin (bukan checkbox)
- Muncul dialog month picker dengan grid 12 bulan
- User bisa pilih multiple bulan sekaligus
- Bulan yang sudah dibayar ditandai hijau dan tidak bisa dipilih lagi
- Total otomatis dihitung berdasarkan jumlah bulan yang dipilih

**Contoh:**
- User pilih Iuran Kebersihan
- Dialog muncul menampilkan Jan-Des
- User centang: Jan, Feb, Mar (3 bulan)
- Total: Rp 100.000 × 3 = Rp 300.000

#### 2. **Notifikasi Dua Arah (In-App)**

**User → Admin** (Saat Bayar):
```dart
await _fs.sendNotification(
  title: "Pembayaran Baru",
  body: "Aceva mengirim pembayaran 2 jenis iuran. Total: Rp 300.000",
  type: "payment",
  targetRole: "admin",
);
```

**Admin → User** (Saat Verifikasi):
```dart
// Otomatis saat admin approve/reject
if (status == 'sukses') {
  sendNotification(
    title: "Pembayaran Disetujui",
    body: "Pembayaran Anda untuk Iuran Kebersihan telah diverifikasi",
    type: "info",
    targetRole: "warga",
  );
}
```

### 📋 Fitur yang Akan Ditambahkan (Berdasarkan Request Terbaru):

#### 1. **Push Notification dengan FCM**
- ✅ Notifikasi muncul di luar app
- ✅ Terintegrasi dengan notification center device
- ✅ HP bergetar saat ada notifikasi
- ✅ Badge counter (angka 1, 2, 3, dst)

#### 2. **Reminder Otomatis Deadline**
- ✅ Notifikasi H-7 sebelum jatuh tempo
- ✅ Notifikasi H-3 sebelum jatuh tempo
- ✅ Notifikasi H-1 sebelum jatuh tempo
- ✅ Notifikasi saat lewat deadline

#### 3. **Setting Deadline Pembayaran**
- ✅ Admin bisa set tanggal jatuh tempo saat tambah iuran
- ✅ Field `deadline` di IuranModel
- ✅ Contoh: "Setiap tanggal 10 setiap bulan"

## 📱 UI/UX Flow

### Flow Pembayaran dengan Pemilihan Bulan:

1. **User buka tab Pembayaran**
   - Melihat list iuran yang tersedia
   - Iuran rutin ada badge "Bulanan"
   - Iuran dadakan ada badge "Sekali/Dadakan"

2. **User tap iuran rutin (misal: Iuran Kebersihan)**
   - Dialog month picker muncul
   - Menampilkan grid 12 bulan (Jan-Des)
   - Bulan yang sudah dibayar berwarna hijau dengan label "Lunas"
   - Bulan yang belum dibayar berwarna abu-abu

3. **User pilih bulan yang mau dibayar**
   - Tap bulan Jan → berubah jadi biru (selected)
   - Tap bulan Feb → berubah jadi biru (selected)
   - Tap bulan Mar → berubah jadi biru (selected)
   - Info di bawah: "3 bulan dipilih • Total: Rp 300.000"

4. **User klik "Simpan"**
   - Dialog tutup
   - Item iuran menampilkan "3 bulan dipilih"
   - Total pembayaran di bawah auto-update

5. **User upload bukti & bayar**
   - Upload foto bukti transfer
   - Klik "Bayar Sekarang"
   - Notifikasi ke admin: "Aceva mengirim pembayaran..."

6. **Admin verifikasi**
   - Admin buka menu "Verifikasi Pembayaran"
   - Lihat detail: 3 transaksi (Jan, Feb, Mar)
   - Approve semua
   - Notifikasi ke user: "Pembayaran disetujui"

## 🔧 Implementasi Teknis

### File yang Dimodifikasi:

#### 1. **`lib/screens/user_screens.dart`**

**State Management:**
```dart
// Tracking selected months per iuran
final Map<String, Set<String>> _selectedMonthsByIuran = {};
final Map<String, Set<String>> _paidMonthsByIuran = {};
```

**Month Picker Dialog:**
```dart
void _showMonthPickerDialog(IuranModel iuran, Set<String> paidMonths) {
  // Grid 12 bulan
  // Bulan yang sudah dibayar = disabled (hijau)
  // Bulan yang dipilih = biru
  // Bulan available = abu-abu
}
```

**Payment Processing:**
```dart
// Create transaction for each selected month
for (var periode in selectedMonths) {
  await _fs.addTransaksi(
    iuranId: iuran.id,
    periode: periode, // "01-2026", "02-2026", etc
    ...
  );
}
```

#### 2. **`lib/services.dart`**

**New Method: `addTransaksi`**
```dart
Future<void> addTransaksi({
  required String iuranId,
  required String userId,
  required String periode,
  required String status,
  ...
})
```

**Enhanced: `updateStatusTransaksi`**
- Otomatis kirim notifikasi saat status berubah
- Approve → notif "Pembayaran Disetujui"
- Reject → notif "Pembayaran Ditolak"

## 📊 Data Structure

### Transaksi Model:
```json
{
  "iuran_id": "abc123",
  "user_id": "user456",
  "user_name": "Aceva",
  "uang": 100000,
  "tipe": "pemasukan",
  "deskripsi": "Bayar: Iuran Kebersihan (01-2026)",
  "timestamp": "2026-01-20T10:30:00Z",
  "status": "menunggu",
  "bukti_gambar": "https://...",
  "periode": "01-2026",
  "metode": "va"
}
```

### Selected Months Format:
```dart
_selectedMonthsByIuran = {
  "iuran_id_1": {"01-2026", "02-2026", "03-2026"},
  "iuran_id_2": {"01-2026"},
}
```

## 🎨 UI Components

### Month Picker Grid:
- **3 kolom × 4 baris** = 12 bulan
- **Warna:**
  - 🟢 Hijau = Sudah dibayar (disabled)
  - 🔵 Biru = Dipilih
  - ⚪ Abu-abu = Available
- **Icon:**
  - ✓ Check circle = Sudah dibayar
  - ✓ Check = Dipilih
  - ○ Circle outline = Available

### Info Banner:
- Menampilkan jumlah bulan dipilih
- Menampilkan total harga
- Update real-time saat user pilih/unpilih bulan

## 🚀 Next Steps (Akan Diimplementasikan)

### 1. Firebase Cloud Messaging (FCM)
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
```

**Features:**
- Push notification di luar app
- Badge counter
- Vibration
- Sound notification

### 2. Scheduled Notifications
```dart
// Cron job atau Cloud Functions
// Check setiap hari jam 09:00
if (today == deadline - 7 days) {
  sendReminder("H-7 jatuh tempo iuran");
}
```

### 3. Deadline Management
```dart
class IuranModel {
  final int deadlineDay; // 1-31 (tanggal jatuh tempo)
  // Contoh: 10 = setiap tanggal 10
}
```

## ✅ Testing Checklist

- [x] User bisa tap iuran rutin untuk buka month picker
- [x] Dialog menampilkan 12 bulan dengan benar
- [x] Bulan yang sudah dibayar disabled (hijau)
- [x] User bisa pilih multiple bulan
- [x] Total auto-update saat pilih bulan
- [x] Simpan button disabled jika tidak ada bulan dipilih
- [x] Setelah simpan, item menampilkan "X bulan dipilih"
- [x] Payment processing create transaksi per bulan
- [x] Notifikasi ke admin saat user bayar
- [x] Notifikasi ke user saat admin verifikasi
- [ ] FCM push notification (belum diimplementasikan)
- [ ] Badge counter (belum diimplementasikan)
- [ ] Vibration (belum diimplementasikan)
- [ ] Deadline reminder (belum diimplementasikan)

## 📝 Notes

- Periode format: `MM-YYYY` (contoh: `01-2026`, `12-2025`)
- Satu transaksi = satu bulan
- Jika user pilih 3 bulan → create 3 transaksi terpisah
- Semua transaksi share bukti pembayaran yang sama
- Admin bisa approve/reject per transaksi atau bulk
