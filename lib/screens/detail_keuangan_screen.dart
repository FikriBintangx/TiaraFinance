import 'package:flutter/material.dart';
import 'package:tiara_fin/services.dart';
import 'package:tiara_fin/models.dart';
// import 'package:tiara_fin/utils.dart'; // Utils ga nemu, anggep aja udah ada atau ntar kita cari.
// Cek import dari user_screens.dart:
// import 'package:tiara_fin/widgets/wavy_navbar.dart';
// ...
// Utils keknya ngumpet di file lain atau nyatu sama user_screens.dart?
// Kalo liat di user_screens.dart sih ada Utils.formatCurrency.
// Yaudah anggep aja ada di 'common.dart' atau copas helpernya kalo kepepet.
// Sebentar, bisa dicari sih sebenernya.
import 'package:intl/intl.dart';

// Copas import yang dibutuhin, soalnya kan nempel di user_screens.dart.
// Kita bakal tempel ginian pake replace_file_content.
// Jadi anggep aja ini nambah di user_screens.dart.

// Asumsi gue kelas ini bakal ditaro di paling bawah user_screens.dart.

class DetailKeuanganScreen extends StatefulWidget {
  const DetailKeuanganScreen({super.key});

  @override
  State<DetailKeuanganScreen> createState() => _DetailKeuanganScreenState();
}

class _DetailKeuanganScreenState extends State<DetailKeuanganScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  
  // Buat Nyaring Data (Filter)
  String _selectedStatus = 'Semua';
  String _selectedCategory = 'Semua';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Rincian Keuangan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTrans = snapshot.data!;
          
          // Oke, ini bagian nyaring datanya alias Filter Logic
          var filtered = allTrans.where((t) {
            // Pencarian
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
               if (!t.deskripsi.toLowerCase().contains(q) && 
                   !t.uang.toString().contains(q)) {
                 return false;
               }
            }
            
            // Statusnya gmn?
            if (_selectedStatus == 'Lunas' && t.status != 'sukses') return false;
            if (_selectedStatus == 'Menunggu' && t.status != 'menunggu') return false;
            
            // Kategorinya apa?
            if (_selectedCategory != 'Semua' && 
                !t.deskripsi.toLowerCase().contains(_selectedCategory.toLowerCase())) {
              return false;
            }
            
            // Tanggalnya masuk range gak?
            if (_selectedDateRange != null) {
              if (t.timestamp.isBefore(_selectedDateRange!.start) ||
                  t.timestamp.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
                return false;
              }
            }
            
            return true;
          }).toList();

          // Itung-itungan Statistik
          final totalBayar = filtered
              .where((t) => t.status == 'sukses')
              .fold(0, (sum, t) => sum + t.uang);
          final totalItems = filtered.length;

          return Column(
            children: [
              // 1. Bagian Pencarian (Search Bar)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi (cth: Keamanan)',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              
              const SizedBox(height: 1), // Garis tipis biar estetik

              // 2. Kartu Ringkasan Statistik
              Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 color: Colors.white,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Ringkasan Filter", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     Row(
                       children: [
                         Expanded(
                           child: _buildStatItem(
                             "Total Dibayar", 
                             Utils.formatCurrency(totalBayar), 
                             Colors.blue
                           ),
                         ),
                         Container(width: 1, height: 40, color: Colors.grey.shade300),
                         Expanded(
                           child: _buildStatItem(
                             "Frekuensi", 
                             "$totalItems Transaksi", 
                             Colors.orange
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
              ),

              // 3. Pilihan Filter
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Tanggal
                      InkWell(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedDateRange == null ? Colors.transparent : Colors.blue.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: _selectedDateRange == null ? Colors.grey : Colors.blue),
                              const SizedBox(width: 6),
                              Text(
                                _selectedDateRange == null ? "Tanggal" : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: _selectedDateRange == null ? Colors.grey : Colors.blue
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Status
                      _buildFilterChip("Semua Status", _selectedStatus == 'Semua', () => setState(() => _selectedStatus = 'Semua')),
                      const SizedBox(width: 8),
                      _buildFilterChip("Lunas", _selectedStatus == 'Lunas', () => setState(() => _selectedStatus = 'Lunas')),
                      const SizedBox(width: 8),
                      _buildFilterChip("Menunggu", _selectedStatus == 'Menunggu', () => setState(() => _selectedStatus = 'Menunggu')),
                      const SizedBox(width: 8),
                      Container(height: 20, width: 1, color: Colors.grey.shade300),
                      const SizedBox(width: 8),
                      // Filter Kategori
                      _buildFilterChip("Keamanan", _selectedCategory == 'Keamanan', () => setState(() => _selectedCategory = _selectedCategory == 'Keamanan' ? 'Semua' : 'Keamanan')),
                      const SizedBox(width: 8),
                      _buildFilterChip("Kebersihan", _selectedCategory == 'Kebersihan', () => setState(() => _selectedCategory = _selectedCategory == 'Kebersihan' ? 'Semua' : 'Kebersihan')),
                    ],
                  ),
                ),
              ),

              // 4. Daftar List Transaksi
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return _buildTransactionCard(t);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransaksiModel t) {
    final isSuccess = t.status == 'sukses';
    return InkWell(
      onTap: () => _showDetail(t),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check : Icons.access_time, 
                color: isSuccess ? Colors.green : Colors.orange,
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(DateFormat("dd MMM yyyy • HH:mm").format(t.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(
               Utils.formatCurrency(t.uang),
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _showDetail(TransaksiModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
             const SizedBox(height: 12),
             Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
             const SizedBox(height: 24),
             const Text("Detail Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(24),
                 child: Column(
                   children: [
                      _detailItem("Status", t.status.toUpperCase(), t.status == 'sukses' ? Colors.green : Colors.orange),
                      _detailItem("Jumlah", Utils.formatCurrency(t.uang), Colors.black),
                      _detailItem("Keterangan", t.deskripsi, Colors.grey.shade700),
                      _detailItem("Tanggal", DateFormat("dd MMM yyyy, HH:mm").format(t.timestamp), Colors.grey.shade700),
                      
                      const SizedBox(height: 24),
                      const Align(alignment: Alignment.centerLeft, child: Text("Bukti Foto", style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: t.buktiGambar != null && t.buktiGambar!.isNotEmpty
                           ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(t.buktiGambar!, fit: BoxFit.cover))
                           : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                      )
                   ],
                 ),
               ),
             ),
          ],
        ),
      )
    );
  }

  Widget _detailItem(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
