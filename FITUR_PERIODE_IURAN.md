# Fitur Periode Iuran - Dokumentasi

## Ringkasan Perubahan

Aplikasi sekarang mendukung **3 jenis periode iuran**:

### 1. **Bulanan (Rutin)**
- Iuran yang dibayar setiap bulan
- Contoh: Iuran Keamanan, Iuran Kebersihan
- Warga bisa bayar untuk beberapa bulan sekaligus (1-12 bulan)

### 2. **Tahunan (Rutin)**
- Iuran yang dibayar setiap tahun
- Contoh: Iuran Tahunan RT/RW
- Warga bisa bayar untuk beberapa tahun sekaligus

### 3. **Sekali/Dadakan**
- Iuran yang hanya dibayar satu kali
- Contoh: Iuran 17an, Iuran Renovasi Gapura, dll
- Hanya bisa dibayar sekali, tidak ada opsi durasi

## Fitur Utama

### Untuk Admin:
1. **Tambah Iuran dengan Periode**
   - Saat menambah iuran baru, admin memilih periode dari dropdown
   - Pilihan: Bulanan (Rutin), Tahunan (Rutin), Sekali/Dadakan

2. **Edit Iuran**
   - Admin bisa mengubah periode iuran yang sudah ada
   - Periode ditampilkan dengan badge warna:
     - 🔵 Biru = Iuran Rutin (Bulanan/Tahunan)
     - 🟠 Orange = Iuran Dadakan/Sekali

### Untuk Warga:
1. **Pembayaran Fleksibel**
   - Untuk iuran rutin: slider durasi 1-12 bulan
   - Slider **auto-update** total pembayaran tanpa refresh halaman
   - Untuk iuran dadakan: tidak ada slider, langsung bayar

2. **Smart Selection**
   - Pilih iuran rutin saja → muncul slider durasi
   - Pilih iuran dadakan saja → muncul info "hanya bisa dibayar sekali"
   - Pilih campuran → muncul slider + info bahwa dadakan hanya sekali

3. **Badge Periode**
   - Setiap item iuran menampilkan badge periode
   - Memudahkan warga membedakan jenis iuran

## Perubahan Teknis

### File yang Dimodifikasi:

1. **`lib/models.dart`**
   - Tambah helper `isRecurring` dan `periodeDisplay` di `IuranModel`
   - Support periode: 'bulanan', 'tahunan', 'sekali'

2. **`lib/services.dart`**
   - Method `tambahIuran()` dan `updateIuran()` sudah support parameter `periode`
   - Method `bayarMultiIuran()` handle perhitungan berbeda untuk recurring vs non-recurring

3. **`lib/screens/admin_screens.dart`**
   - Dialog tambah/edit iuran dengan dropdown periode
   - List iuran menampilkan badge periode

4. **`lib/screens/user_screens.dart`**
   - Slider durasi yang smart (hanya muncul untuk iuran rutin)
   - Auto-update total saat slider berubah (pakai `setState`)
   - Badge periode di setiap item iuran
   - Perhitungan total yang benar untuk mixed selection

## Cara Penggunaan

### Admin - Menambah Iuran Dadakan (Contoh: Iuran 17an)

1. Klik tombol "+" di dashboard admin
2. Pilih "Catat Iuran Baru"
3. Isi form:
   - Nama: "Iuran 17an"
   - Harga: 50000
   - Periode: **Sekali/Dadakan (17an, dll)**
   - Deskripsi: "Iuran perayaan 17 Agustus"
4. Klik "Buat"

### Warga - Membayar Iuran

**Skenario 1: Bayar iuran bulanan untuk 6 bulan**
1. Buka tab "Pembayaran"
2. Pilih iuran bulanan (misal: Iuran Keamanan, Kebersihan)
3. Geser slider ke "6 Bulan"
4. Total otomatis update (misal: Rp 150.000 × 6 = Rp 900.000)
5. Upload bukti → Bayar

**Skenario 2: Bayar iuran dadakan**
1. Buka tab "Pembayaran"
2. Pilih iuran dadakan (misal: Iuran 17an)
3. Tidak ada slider (otomatis 1x bayar)
4. Upload bukti → Bayar

**Skenario 3: Bayar campuran**
1. Pilih iuran bulanan + dadakan
2. Slider muncul untuk iuran bulanan
3. Iuran dadakan tetap dihitung 1x
4. Total = (iuran bulanan × durasi) + iuran dadakan

## Catatan Penting

- ✅ Slider **tidak refresh halaman** saat digeser (pakai `setState()`)
- ✅ Total pembayaran **auto-update** real-time
- ✅ Badge periode membantu identifikasi jenis iuran
- ✅ Validasi: iuran dadakan tidak bisa dibayar berkali-kali dalam periode yang sama
- ✅ Backward compatible: iuran lama tanpa periode akan default ke 'bulanan'

## Testing Checklist

- [ ] Admin bisa tambah iuran dengan periode berbeda
- [ ] Admin bisa edit periode iuran existing
- [ ] Badge periode muncul di list admin
- [ ] Badge periode muncul di list pembayaran warga
- [ ] Slider hanya muncul untuk iuran rutin
- [ ] Slider auto-update total tanpa refresh
- [ ] Iuran dadakan tidak bisa pilih durasi
- [ ] Mixed selection (rutin + dadakan) dihitung dengan benar
- [ ] Pembayaran berhasil tersimpan dengan periode yang benar
