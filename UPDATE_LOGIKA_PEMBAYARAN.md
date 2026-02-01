# 🔧 Update: Logika Pembayaran Iuran Recurring

## Perubahan yang Dilakukan

### **Sebelumnya** ❌
- Jika ada **satu bulan saja** yang sudah dibayar, seluruh iuran jadi **disabled**
- User tidak bisa bayar bulan-bulan lainnya yang belum dibayar
- Harus menunggu admin atau sistem untuk reset status

### **Sekarang** ✅
- **Iuran Recurring (Bulanan/Tahunan)**:
  - Hanya disabled jika **SEMUA 12 bulan** sudah dibayar
  - Jika baru bayar 3 bulan, masih bisa pilih 9 bulan lainnya
  - Bulan yang sudah dibayar tetap **diblok (hijau)** di month picker
  
- **Iuran One-Time (Sekali)**:
  - Tetap seperti sebelumnya
  - Disabled setelah dibayar sekali

---

## Contoh Penggunaan

### **Scenario 1: Iuran Bulanan - Sebagian Bulan Dibayar**

```
Iuran: Kebersihan (Rp 100.000/bulan)
Status: Sudah bayar Januari, Februari, Maret

UI yang ditampilkan:
┌─────────────────────────────────────┐
│ ☑ Iuran Kebersihan      [Bulanan]   │
│    Deskripsi iuran                  │
│    3 bulan sudah dibayar            │ ← Info baru
│                        Rp 100.000   │
└─────────────────────────────────────┘

Saat di-tap:
- Month picker terbuka
- Januari, Februari, Maret = HIJAU (disabled)
- April - Desember = PUTIH (bisa dipilih)
- User bisa pilih April, Mei, Juni untuk dibayar
```

### **Scenario 2: Iuran Bulanan - Semua Bulan Dibayar**

```
Iuran: Kebersihan (Rp 100.000/bulan)
Status: Sudah bayar semua 12 bulan

UI yang ditampilkan:
┌─────────────────────────────────────┐
│ ✓ Iuran Kebersihan      [Bulanan]   │
│    Lunas semua bulan                │ ← Disabled
│                        Rp 100.000   │
└─────────────────────────────────────┘

Behavior:
- Tidak bisa di-tap (disabled)
- Warna abu-abu
- Icon check hijau
```

### **Scenario 3: Iuran Sekali - Belum Dibayar**

```
Iuran: Sumbangan 17 Agustus (Rp 50.000)
Status: Belum dibayar

UI yang ditampilkan:
┌─────────────────────────────────────┐
│ ☐ Sumbangan 17 Agustus  [Sekali]    │
│    Untuk perayaan kemerdekaan       │
│                         Rp 50.000   │
└─────────────────────────────────────┘

Saat di-tap:
- Langsung terselect (checkbox centang)
- Tidak ada month picker
- Langsung masuk ke total pembayaran
```

### **Scenario 4: Iuran Sekali - Sudah Dibayar**

```
Iuran: Sumbangan 17 Agustus (Rp 50.000)
Status: Sudah dibayar

UI yang ditampilkan:
┌─────────────────────────────────────┐
│ ✓ Sumbangan 17 Agustus  [Sekali]    │
│    Lunas bulan ini                  │ ← Disabled
│                         Rp 50.000   │
└─────────────────────────────────────┘

Behavior:
- Tidak bisa di-tap (disabled)
- Warna abu-abu
- Icon check hijau
```

---

## Kode yang Diubah

### **File**: `lib/screens/user_screens.dart`

#### **Logika isPaid** (Baris ~1909-1918):

```dart
// BEFORE
bool isPaid = _paidIuranIds.contains(iuran.id);

// AFTER
final paidMonths = _paidMonthsByIuran[iuran.id] ?? {};

bool isPaid;
if (iuran.isRecurring) {
  isPaid = paidMonths.length >= 12; // All months paid
} else {
  isPaid = _paidIuranIds.contains(iuran.id); // One-time paid
}
```

#### **Subtitle Info** (Baris ~1961-1977):

```dart
// BEFORE
if (isPaid)
  const Text("Lunas bulan ini", ...)

// AFTER
if (isPaid)
  Text(
    iuran.isRecurring ? "Lunas semua bulan" : "Lunas bulan ini",
    ...
  )
else ...[
  Text(iuran.deskripsi, ...),
  // NEW: Show paid months count
  if (iuran.isRecurring && paidMonths.isNotEmpty)
    Text('${paidMonths.length} bulan sudah dibayar', ...),
  // Existing: Show selected months count
  if (iuran.isRecurring && isSelected && selectedMonths.isNotEmpty)
    Text('${selectedMonths.length} bulan dipilih', ...),
]
```

---

## Benefit untuk User

1. **Lebih Fleksibel**: Bisa bayar iuran bulanan secara bertahap
2. **Informasi Jelas**: Tahu berapa bulan yang sudah dibayar
3. **Tidak Terblokir**: Tidak perlu menunggu admin untuk bisa bayar bulan berikutnya
4. **Visual Feedback**: Bulan yang sudah dibayar tetap ditampilkan (hijau) di month picker

---

## Testing

### **Test Case 1**: Iuran Recurring - Partial Payment
1. Login sebagai user
2. Bayar Januari, Februari untuk Iuran Kebersihan
3. Kembali ke halaman pembayaran
4. **Expected**: Iuran Kebersihan masih bisa dipilih
5. Tap iuran → Month picker terbuka
6. **Expected**: Jan & Feb hijau (disabled), Mar-Dec putih (available)
7. Pilih Maret, April, Mei → Bayar
8. **Expected**: Berhasil, total = 3 bulan × harga

### **Test Case 2**: Iuran Recurring - Full Payment
1. Bayar semua 12 bulan untuk Iuran Kebersihan
2. Kembali ke halaman pembayaran
3. **Expected**: Iuran Kebersihan disabled (abu-abu, check hijau)
4. **Expected**: Subtitle: "Lunas semua bulan"

### **Test Case 3**: Iuran One-Time
1. Bayar Sumbangan 17 Agustus
2. Kembali ke halaman pembayaran
3. **Expected**: Sumbangan disabled (abu-abu, check hijau)
4. **Expected**: Subtitle: "Lunas bulan ini"

---

## Catatan Teknis

- **Recurring iuran**: Menggunakan `paidMonths.length >= 12` untuk cek lunas
- **One-time iuran**: Menggunakan `_paidIuranIds.contains(iuran.id)` untuk cek lunas
- **Month picker**: Bulan yang sudah dibayar tetap disabled (hijau) di dialog
- **Total calculation**: Hanya menghitung bulan yang dipilih (belum dibayar)

---

**Update Date**: 20 Januari 2026  
**Status**: ✅ Implemented & Ready for Testing
