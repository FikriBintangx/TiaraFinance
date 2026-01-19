import 'package:flutter/material.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:tiara_fin/screens/user_screens.dart'; // for AppColors
import 'package:tiara_fin/screens/feature_screens.dart'; // for Create/Detail screens

class PengumumanListScreen extends StatefulWidget {
  final UserModel currentUser;
  const PengumumanListScreen({super.key, required this.currentUser});

  @override
  State<PengumumanListScreen> createState() => _PengumumanListScreenState();
}

class _PengumumanListScreenState extends State<PengumumanListScreen> {
  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengumuman'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => CreatePengumumanScreen(currentUser: widget.currentUser))
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<PengumumanModel>>(
        stream: _fs.getPengumuman(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text("Belum ada pengumuman.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = list[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(Utils.formatDateTime(p.date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${p.viewers.length} Dilihat", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPengumumanScreen(pengumuman: p, currentUser: widget.currentUser),
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
