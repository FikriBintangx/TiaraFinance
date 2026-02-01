import 'package:flutter/material.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.nama),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') _exportPdf(context);
              if (value == 'password') _showChangePasswordDialog(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Ubah Password'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Profile
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    widget.user.nama.isNotEmpty ? widget.user.nama[0] : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.user.email, style: const TextStyle(color: Colors.grey)),
                      if (widget.user.blok.isNotEmpty)
                        Text('${widget.user.blok} / ${widget.user.noRumah}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Year Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Periode:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _selectedYear--),
                    ),
                    Text(
                      _selectedYear.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _selectedYear++),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Payment Summary by Iuran Type
          Expanded(
            child: StreamBuilder<List<IuranModel>>(
              stream: _fs.getIuranList(),
              builder: (context, iuranSnapshot) {
                if (!iuranSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allIuran = iuranSnapshot.data!;

                return StreamBuilder<List<TransaksiModel>>(
                  stream: _fs.getUserTransaksi(widget.user.id),
                  builder: (context, transSnapshot) {
                    if (!transSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allTrans = transSnapshot.data!;
                    
                    // Filter transactions for selected year and successful payments
                    final yearTrans = allTrans.where((t) {
                      return t.timestamp.year == _selectedYear &&
                             t.tipe == 'pemasukan' &&
                             t.status == 'sukses';
                    }).toList();

                    if (allIuran.isEmpty) {
                      return const Center(child: Text("Belum ada jenis iuran"));
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Card
                        _buildSummaryCard(allIuran, yearTrans),
                        const SizedBox(height: 16),
                        
                        // Per Iuran Breakdown
                        const Text(
                          'Rincian per Jenis Iuran',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        ...allIuran.map((iuran) {
                          return _buildIuranCard(iuran, yearTrans);
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<IuranModel> allIuran, List<TransaksiModel> yearTrans) {
    int totalPaid = yearTrans.fold(0, (sum, t) => sum + t.uang);
    int totalIuranTypes = allIuran.length;
    
    // Count how many iuran types have been paid at least once
    Set<String> paidIuranIds = yearTrans
        .where((t) => t.iuranId != null)
        .map((t) => t.iuranId!)
        .toSet();
    int paidTypes = paidIuranIds.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Pembayaran',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedYear.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Dibayar',
                  Utils.formatCurrency(totalPaid),
                  Icons.payments,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Jenis Iuran',
                  '$paidTypes / $totalIuranTypes',
                  Icons.category,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranCard(IuranModel iuran, List<TransaksiModel> yearTrans) {
    // Get transactions for this specific iuran
    final iuranTrans = yearTrans.where((t) => t.iuranId == iuran.id).toList();
    
    // Get paid months (periode format: MM-YYYY)
    Set<String> paidMonths = iuranTrans
        .map((t) => t.periode)
        .where((p) => p.isNotEmpty)
        .toSet();
    
    // Calculate total paid for this iuran
    int totalPaid = iuranTrans.fold(0, (sum, t) => sum + t.uang);
    int paidCount = paidMonths.length;
    
    // For recurring iuran, show monthly breakdown
    bool isRecurring = iuran.isRecurring;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: paidCount > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            paidCount > 0 ? Icons.check_circle : Icons.pending,
            color: paidCount > 0 ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          iuran.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isRecurring ? Colors.blue[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    iuran.periodeDisplay,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isRecurring ? Colors.blue[700] : Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isRecurring)
                  Text(
                    '$paidCount / 12 bulan',
                    style: TextStyle(
                      fontSize: 12,
                      color: paidCount >= 12 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    paidCount > 0 ? 'Sudah dibayar' : 'Belum dibayar',
                    style: TextStyle(
                      fontSize: 12,
                      color: paidCount > 0 ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Utils.formatCurrency(totalPaid),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            Text(
              '${Utils.formatCurrency(iuran.harga)}/bln',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecurring) ...[
                  const Text(
                    'Status Pembayaran Bulanan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyGrid(paidMonths),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Riwayat Transaksi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (iuranTrans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada pembayaran',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...iuranTrans.map((t) => _buildTransactionItem(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGrid(Set<String> paidMonths) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(12, (index) {
        final month = index + 1;
        final monthStr = month.toString().padLeft(2, '0');
        final periode = '$monthStr-$_selectedYear';
        final isPaid = paidMonths.contains(periode);
        
        return Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPaid ? Colors.green[700]! : Colors.grey[400]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                monthNames[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPaid ? Colors.white : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                isPaid ? Icons.check : Icons.close,
                size: 14,
                color: isPaid ? Colors.white : Colors.grey[600],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTransactionItem(TransaksiModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Utils.formatDate(t.timestamp),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Periode: ${t.periode}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            Utils.formatCurrency(t.uang),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    // TODO: Implement PDF export with categorized payment history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur export PDF segera hadir')),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Password Warga"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan password baru untuk user ini."),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.length < 6) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal 6 karakter")));
                 return;
              }
              
              Navigator.pop(ctx);
              try {
                await _fs.updateUserProfile(widget.user.id, password: passCtrl.text);
                
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah"), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal ubah password: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }
}
