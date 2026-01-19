import 'package:flutter/material.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.nama),
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
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    user.nama.isNotEmpty ? user.nama[0] : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user.email, style: const TextStyle(color: Colors.grey)),
                      if (user.blok.isNotEmpty)
                        Text('${user.blok} / ${user.noRumah}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Transaction History
          Expanded(
            child: StreamBuilder<List<TransaksiModel>>(
              stream: fs.getUserTransaksi(user.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final trans = snapshot.data!;
                if (trans.isEmpty) return const Center(child: Text("Belum ada riwayat transaksi"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trans.length,
                  itemBuilder: (context, index) {
                    final item = trans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.status == 'sukses' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.tipe == 'pemasukan' ? Icons.arrow_downward : Icons.arrow_upward,
                            color: item.status == 'sukses' ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(item.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(Utils.formatDate(item.timestamp)),
                        trailing: Text(
                          Utils.formatCurrency(item.uang),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.tipe == 'pemasukan' ? Colors.green : Colors.red,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow("ID Transaksi", item.id),
                                _buildDetailRow("Status", item.status.toUpperCase()),
                                _buildDetailRow("Periode", item.periode ?? '-'),
                                const SizedBox(height: 12),
                                if (item.buktiGambar != null && item.buktiGambar!.isNotEmpty) ...[
                                  const Text("Bukti Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.buktiGambar!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        height: 100,
                                        color: Colors.grey.shade200,
                                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                ] else 
                                  const Text("Tidak ada bukti gambar", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              ],
                            ),
                          )
                        ],
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
