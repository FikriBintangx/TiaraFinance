# Fitur Riwayat Pembayaran Terkategorisasi - Dokumentasi

## Ringkasan Fitur

Halaman detail warga sekarang menampilkan **riwayat pembayaran yang dikategorikan per jenis iuran** dengan visualisasi status pembayaran bulanan.

## Fitur Utama

### 1. **Pemilih Tahun**
- Navigasi tahun dengan tombol prev/next
- Menampilkan data pembayaran untuk tahun yang dipilih
- Default: tahun berjalan

### 2. **Ringkasan Pembayaran**
Card summary yang menampilkan:
- **Total Dibayar**: Total uang yang sudah dibayar dalam tahun tersebut
- **Jenis Iuran**: Berapa jenis iuran yang sudah dibayar dari total yang tersedia
  - Contoh: "3 / 5" = sudah bayar 3 dari 5 jenis iuran

### 3. **Rincian per Jenis Iuran**

Setiap jenis iuran ditampilkan dalam card expansion dengan informasi:

#### Untuk Iuran Rutin (Bulanan/Tahunan):
- ✅ **Status pembayaran**: "X / 12 bulan"
- ✅ **Grid kalender bulanan** dengan indikator visual:
  - 🟢 Hijau + ✓ = Sudah dibayar
  - ⚪ Abu-abu + ✗ = Belum dibayar
- ✅ **Total dibayar** untuk iuran tersebut
- ✅ **Harga per bulan**
- ✅ **Riwayat transaksi** detail dengan tanggal dan periode

#### Untuk Iuran Dadakan/Sekali:
- ✅ Status: "Sudah dibayar" atau "Belum dibayar"
- ✅ Total dibayar
- ✅ Riwayat transaksi

### 4. **Visualisasi Grid Bulanan**

Grid 12 bulan menampilkan status pembayaran per bulan:
```
[Jan✓] [Feb✓] [Mar✗] [Apr✗] [Mei✗] [Jun✗]
[Jul✗] [Agu✗] [Sep✗] [Okt✗] [Nov✗] [Des✗]
```

- Hijau = Sudah dibayar
- Abu-abu = Belum dibayar
- Mudah melihat bulan mana yang sudah/belum dibayar

## Contoh Tampilan

### Skenario 1: Warga Aktif
**Iuran Kebersihan** (Bulanan)
- Status: 6 / 12 bulan ⚠️
- Total Dibayar: Rp 600.000
- Grid: Jan-Jun hijau, Jul-Des abu-abu
- Riwayat: 6 transaksi tercatat

**Iuran 17an** (Sekali)
- Status: Sudah dibayar ✅
- Total Dibayar: Rp 50.000
- Riwayat: 1 transaksi

### Skenario 2: Warga Belum Bayar
**Iuran Keamanan** (Bulanan)
- Status: 0 / 12 bulan ❌
- Total Dibayar: Rp 0
- Grid: Semua abu-abu
- Riwayat: Belum ada pembayaran

## Keuntungan Fitur Ini

### Untuk Admin:
1. **Monitoring Mudah**: Langsung lihat warga mana yang rajin/telat bayar
2. **Detail per Iuran**: Tahu persis iuran mana yang sering telat
3. **Visualisasi Jelas**: Grid bulanan memudahkan identifikasi pola pembayaran
4. **Filter Tahun**: Bisa cek riwayat tahun-tahun sebelumnya

### Untuk Warga:
1. **Transparansi**: Bisa lihat riwayat pembayaran sendiri dengan jelas
2. **Reminder Visual**: Grid merah/hijau mengingatkan bulan mana yang belum dibayar
3. **Bukti Pembayaran**: Semua transaksi tercatat dengan detail

## Implementasi Teknis

### File yang Dimodifikasi:
- **`lib/screens/user_detail_screen.dart`**

### Perubahan Utama:

1. **StatefulWidget**: Diubah dari StatelessWidget untuk support year selector
2. **Dual StreamBuilder**: 
   - Stream 1: List semua jenis iuran
   - Stream 2: List transaksi user
3. **Filtering Smart**:
   ```dart
   final yearTrans = allTrans.where((t) {
     return t.timestamp.year == _selectedYear &&
            t.tipe == 'pemasukan' &&
            t.status == 'sukses';
   }).toList();
   ```
4. **Grouping per Iuran**:
   ```dart
   final iuranTrans = yearTrans.where((t) => t.iuranId == iuran.id).toList();
   ```
5. **Monthly Grid Generator**:
   - Generate 12 container untuk Jan-Des
   - Check apakah periode (MM-YYYY) ada di paidMonths
   - Warna hijau jika sudah bayar, abu-abu jika belum

### Widget Hierarchy:
```
UserDetailScreen
├── AppBar (dengan year selector)
├── Profile Header
├── Year Selector (prev/next buttons)
└── StreamBuilder (Iuran + Transaksi)
    ├── Summary Card
    │   ├── Total Dibayar
    │   └── Jenis Iuran Terbayar
    └── List Iuran Cards
        └── ExpansionTile per Iuran
            ├── Monthly Grid (jika recurring)
            └── Transaction History
```

## Cara Penggunaan

### Admin - Melihat Detail Warga

1. Buka menu "Laporan Warga" di admin panel
2. Klik salah satu warga dari list
3. Halaman detail warga terbuka dengan:
   - Info profil warga
   - Selector tahun (default: tahun ini)
   - Ringkasan pembayaran tahun ini
   - Rincian per jenis iuran

4. **Navigasi Tahun**:
   - Klik `<` untuk tahun sebelumnya
   - Klik `>` untuk tahun berikutnya

5. **Lihat Detail Iuran**:
   - Klik card iuran untuk expand
   - Lihat grid bulanan (untuk iuran rutin)
   - Lihat riwayat transaksi detail

### Interpretasi Status:

**Iuran Rutin:**
- `12 / 12 bulan` 🟢 = Lunas setahun
- `6 / 12 bulan` 🟠 = Baru bayar 6 bulan
- `0 / 12 bulan` 🔴 = Belum bayar sama sekali

**Iuran Dadakan:**
- `Sudah dibayar` 🟢 = Lunas
- `Belum dibayar` 🔴 = Belum bayar

## Catatan Penting

- ✅ Data real-time dari Firestore (auto-update)
- ✅ Hanya menghitung transaksi dengan status "sukses"
- ✅ Periode format: MM-YYYY (contoh: 01-2026, 02-2026)
- ✅ Grid bulanan hanya muncul untuk iuran recurring
- ✅ Iuran dadakan tidak ada grid, hanya status sudah/belum
- ✅ Total dibayar = sum semua transaksi sukses untuk iuran tersebut

## Future Enhancements

- [ ] Export PDF dengan breakdown per iuran
- [ ] Filter by status (lunas/belum lunas)
- [ ] Notifikasi otomatis untuk warga yang telat bayar
- [ ] Grafik trend pembayaran per tahun
- [ ] Perbandingan pembayaran antar warga
