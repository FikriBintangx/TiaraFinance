import 'package:flutter/material.dart';
import 'package:tiara_fin/widgets/wavy_navbar.dart';
import 'package:flutter/services.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:tiara_fin/screens/auth_screens.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tiara_fin/screens/notification_screen.dart';
import 'package:tiara_fin/screens/forum_screen.dart';
import 'package:tiara_fin/screens/edit_profile_screen.dart';
import 'package:tiara_fin/widgets/animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiara_fin/widgets/skeleton_loader.dart';
import 'package:tiara_fin/screens/feature_screens.dart';
import 'package:tiara_fin/widgets/empty_state.dart';
import 'package:tiara_fin/widgets/tappable_card.dart';
import 'package:tiara_fin/security_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tiara_fin/message_helper.dart';

// ========== CONSTANTS ==========
class AppColors {
  static const primary = Color(0xFF00D09C);
  static const secondary = Color(0xFF00B882);
  static const success = Color(0xFF00D09C);
  static const warning = Color(0xFFFFB800);
  static const danger = Color(0xFFFF3B30);
  static const info = Color(0xFF007AFF);
  static const dark = Color(0xFF1A1A1A);
  static const grey = Color(0xFF8E8E93);
  static const lightGrey = Color(0xFFF5F5F5);
  static const purple = Color(0xFFAF52DE);
}

class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    var secondControlPoint = Offset(size.width - (size.width / 3.25), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ========== MAIN WRAPPER ==========
class UserMainScreen extends StatefulWidget {
  final int initialIndex;
  const UserMainScreen({super.key, this.initialIndex = 0});
  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;


  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      const BerandaScreen(),
      const RiwayatScreen(),
      const PembayaranScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating effect over body content
      body: Stack(
        children: [
          // Main Body
          _screens[_selectedIndex],
          
          // Floating Navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: WavyBottomBar(
                selectedIndex: _selectedIndex,
                items: const [
                  Icons.dashboard_rounded,
                  Icons.history_rounded,
                  Icons.payment_rounded,
                  Icons.person_rounded,
                ],
                onItemSelected: (i) {
                   HapticFeedback.lightImpact();
                   setState(() => _selectedIndex = i);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  final RefreshController _refreshController = RefreshController();
  
  UserModel? _currentUser;
  List<IuranModel> _allIuran = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    _currentUser = await _auth.getCurrentUser();
    _fs.getIuranList().listen((list) {
      if (mounted) setState(() => _allIuran = list);
    });
    if (mounted) setState(() {});
  }

  void _showAddForumDialog(BuildContext context) {
    if (_currentUser == null) return;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Buat Diskusi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Topik", hintText: "Contoh: Keamanan"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Detail", hintText: "Deskripsi (Opsional)"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text("Diskusi akan diverifikasi Admin.", style: TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                MessageHelper.showLoading(context, message: "Mengirim...");
                await _fs.requestForum(_currentUser!.id, _currentUser!.nama, titleCtrl.text, descCtrl.text);
                if (mounted) {
                   MessageHelper.hideLoading(context);
                   MessageHelper.showSuccess(context, "Terkirim! Menunggu verifikasi.");
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Kirim"),
          )
        ],
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
             Icon(Icons.warning_rounded, color: Colors.red, size: 32),
             SizedBox(width: 10),
             Text("Panggilan Darurat", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Apakah Anda dalam situasi darurat? Tekan tombol di bawah untuk bantuan segera.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _buildEmergencyAction(
              "Panggil Satpam",
              "08123456789", // Dummy number
              Icons.shield,
              const Color(0xFF00796B),
              () async {
                final Uri launchUri = Uri(scheme: 'tel', path: '08123456789');
                try {
                  await launchUrl(launchUri);
                } catch (e) {
                   debugPrint("Could not launch $launchUri");
                }
              }
            ),
             const SizedBox(height: 12),
            _buildEmergencyAction(
              "Ambulans",
              "118",
              Icons.medical_services,
              Colors.redAccent,
              () async {
                 final Uri launchUri = Uri(scheme: 'tel', path: '118');
                 try {
                   await launchUrl(launchUri);
                 } catch (e) {
                    debugPrint("Could not launch $launchUri");
                 }
              }
            ),
             const SizedBox(height: 12),
            _buildEmergencyAction(
              "Pemadam Kebakaran",
              "113",
              Icons.fire_truck,
              Colors.orange,
              () async {
                 final Uri launchUri = Uri(scheme: 'tel', path: '113');
                 try {
                   await launchUrl(launchUri);
                 } catch (e) {
                    debugPrint("Could not launch $launchUri");
                 }
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAction(String label, String subLabel, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.call, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Fix overlapping
        child: FloatingActionButton(
          onPressed: () => _showAddForumDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        header: WaterDropMaterialHeader(
          backgroundColor: AppColors.primary,
          color: Colors.white,
          distance: 60,
        ),
        onRefresh: () async {
           HapticFeedback.mediumImpact(); // Feedback saat refresh
           await Future.delayed(const Duration(seconds: 1));
           _loadData(); // Reload data
           _refreshController.refreshCompleted();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 160),
          child: Column(
            children: [
              // Wavy Header Section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: WavyClipper(),
                    child: Container(
                      height: 220,
                      decoration: const BoxDecoration(
                         gradient: LinearGradient(
                          colors: [Color(0xFF00796B), Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                               CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white24,
                                  child: Text(
                                    _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                               ),
                               const SizedBox(width: 12),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   const Text(
                                     'Selamat Pagi,',
                                     style: TextStyle(color: Colors.white70, fontSize: 14),
                                   ),
                                   Text(
                                     _currentUser?.nama ?? 'Warga',
                                     style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                   ),
                                 ],
                               ),
                            ],
                          ),
                          Row(
                            children: [
                               // SOS Button
                               GestureDetector(
                                onTap: () {
                                  HapticFeedback.heavyImpact(); // Getaran kuat untuk emergency
                                  _showEmergencyDialog(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.9), // Bright red for emergency
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 4),
                                      Text(
                                        "SOS",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                          
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                                  child: const Icon(Icons.notifications_outlined, color: Colors.white),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  
                  // Balance Card Overlapping
                  Padding(
                    padding: const EdgeInsets.only(top: 140, left: 16, right: 16),
                    child: _buildBalanceCard(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 4 Icon Menu Grid
              Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: FadeInSlide.delayed(
                   delay: const Duration(milliseconds: 200),
                   child: _buildMenuGrid(context),
                 ),
              ),
              
              const SizedBox(height: 24),
              
               // Pemberitahuan Penting
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    _buildSectionHeader('Pemberitahuan', null),
                    SizedBox(
                      height: 170,
                      child: StreamBuilder<List<PengumumanModel>>(
                        stream: _fs.getPengumuman(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final list = snapshot.data!;
                          if (list.isEmpty) return const Center(child: Text("Belum ada pengumuman"));
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: list.length,
                            itemBuilder: (context, index) => _buildRealAnnouncementCard(list[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Statistik Keuangan
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    _buildSectionHeader('Statistik Keuangan', null),
                    Container(
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2))],
                      ),
                      child: StreamBuilder<List<TransaksiModel>>(
                        stream: _fs.getTransaksiList(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          
                          // Process Data
                          final trans = snapshot.data!;
                          final now = DateTime.now();
                          final List<Map<String, dynamic>> monthlyStats = [];

                          for (int i = 5; i >= 0; i--) {
                            final date = DateTime(now.year, now.month - i, 1);
                            final monthTrans = trans.where((t) => 
                              t.timestamp.year == date.year && t.timestamp.month == date.month && t.status == 'sukses'
                            ).toList();
                            
                            double income = 0;
                            double expense = 0;
                            
                            for (var t in monthTrans) {
                              if (t.tipe == 'pemasukan') income += t.uang;
                              if (t.tipe == 'pengeluaran') expense += t.uang;
                            }
                            
                            monthlyStats.add({
                              'month': date.month,
                              'income': income,
                              'expense': expense,
                            });
                          }

                          double maxVal = 0;
                          for(var m in monthlyStats) {
                            if (m['income'] > maxVal) maxVal = m['income'];
                            if (m['expense'] > maxVal) maxVal = m['expense'];
                          }
                          if (maxVal == 0) maxVal = 100;

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxVal * 1.2,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => Colors.blueGrey,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      Utils.formatCurrency(rod.toY.toInt()),
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < monthlyStats.length) {
                                        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            monthNames[monthlyStats[index]['month'] - 1],
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: monthlyStats.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (data['income'] as double),
                                      color: AppColors.success,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: (data['expense'] as double),
                                      color: AppColors.danger,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // Aktivitas Terakhir
              FadeInSlide.delayed(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    _buildSectionHeader('Aktivitas Terakhir', null),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<List<TransaksiModel>>(
                        stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Column(
                              children: List.generate(3, (index) => const TransactionSkeletonCard()),
                            );
                          }
                          final recent = snapshot.data!.take(3).toList();
                          if (recent.isEmpty) {
                            return const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'Belum Ada Aktivitas',
                              message: 'Transaksi kamu akan muncul di sini',
                            );
                          }
                          
                          return Column(
                            children: recent.map((t) => _buildRecentTransactionItem(t)).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealAnnouncementCard(PengumumanModel item) {
    if (_currentUser == null) return const SizedBox.shrink();
    bool isNew = !item.viewers.contains(_currentUser!.id);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPengumumanScreen(pengumuman: item, currentUser: _currentUser!))),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: AppColors.primary.withOpacity(0.1),
                  image: item.imageUrls.isNotEmpty ? DecorationImage(image: NetworkImage(item.imageUrls.first), fit: BoxFit.cover) : null,
                ),
                child: item.imageUrls.isEmpty ? const Center(child: Icon(Icons.campaign, color: AppColors.primary, size: 40)) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (isNew) Container(margin: const EdgeInsets.only(left: 6), width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(Utils.formatDate(item.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMenuGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildMenuIcon(Icons.history, 'Riwayat', AppColors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatScreen())))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.receipt_long, 'Tagihan', AppColors.danger, () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 2)), (r) => false))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.forum, 'Diskusi', AppColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen())))),
        const SizedBox(width: 12),
        Expanded(child: _buildMenuIcon(Icons.people, 'Warga', AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PengaduanScreen())))), // Redirect to Info Warga/Pengaduan
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return TappableCard(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(String title, String time, String imagePath) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
             child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text("Klik untuk detail", style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return StreamBuilder<List<TransaksiModel>>(
      stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
      builder: (context, snapshot) {
         int tagihanBelumLunas = 0;
         bool isLunas = false;
         
         if (snapshot.hasData) {
            final now = DateTime.now();
            int totalMustPay = _allIuran.fold(0, (sum, i) => sum + i.harga);
             final paidTrans = snapshot.data!.where((t) {
                 if (t.tipe != 'pemasukan' || t.status == 'gagal') return false;
                 final tDate = t.timestamp;
                 return tDate.month == now.month && tDate.year == now.year;
              });
             final paidIuranIds = paidTrans.map((t) => t.iuranId).toSet();
             int paidAmount = 0;
             for(var iuran in _allIuran) {
                 if(paidIuranIds.contains(iuran.id)) paidAmount += iuran.harga;
             }
             tagihanBelumLunas = totalMustPay - paidAmount;
             if (tagihanBelumLunas <= 0) {
                 tagihanBelumLunas = 0;
                 if (_allIuran.isNotEmpty) isLunas = true;
             }
         }

         return Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(20),
             boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
             ],
           ),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text("Sisa Tagihan Bulan Ini", style: TextStyle(color: Colors.grey, fontSize: 12)),
                   const SizedBox(height: 5),
                   Text(
                     isLunas ? "Lunas 🎉" : Utils.formatCurrency(tagihanBelumLunas),
                     style: TextStyle(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: isLunas ? AppColors.success : Colors.black87,
                     ),
                   ),
                 ],
               ),
               ElevatedButton(
                 onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 2)),
                      (route) => false,
                    );
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                 ),
                 child: const Text("Bayar", style: TextStyle(color: Colors.white)),
               ),
             ],
           ),
         );
      }
    );
  }
  
  Widget _buildRecentTransactionItem(TransaksiModel t) {
     final bool isSuccess = t.status == 'sukses';
     return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Icon(
                 isSuccess ? Icons.check_circle : Icons.access_time_filled,
                 color: isSuccess ? Colors.green : Colors.orange,
                 size: 20,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(t.deskripsi, style: const TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text(Utils.formatDate(t.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                 ],
               ),
             ),
             Text(
               Utils.formatCurrency(t.uang),
               style: TextStyle(fontWeight: FontWeight.bold, color: t.tipe == 'pengeluaran' ? Colors.red : Colors.black),
             )
          ],
        ),
     );
  }
}

// ========== RIWAYAT SCREEN (Gambar 1) ==========
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: _fs.getUserTransaksi(_currentUser?.id ?? 'none'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(5, (index) => const TransactionSkeletonCard()),
            );
          }

          final allTrans = snapshot.data!;
          final currentYear = DateTime.now().year;
          final totalThisYear = allTrans
              .where((t) => t.status == 'sukses' && t.timestamp.year == currentYear)
              .fold(0, (sum, t) => sum + t.uang);
          final tagihanNanti = allTrans
              .where((t) => t.status == 'menunggu')
              .fold(0, (sum, t) => sum + t.uang);

          // Filter transactions
          var filteredTrans = allTrans;
          if (_selectedFilter == 'Lunas') {
            filteredTrans = allTrans
                .where((t) => t.status == 'sukses')
                .toList();
          } else if (_selectedFilter == 'Menunggu') {
            filteredTrans = allTrans
                .where((t) => t.status == 'menunggu')
                .toList();
          }

          // Group by smart date labels
          Map<String, List<TransaksiModel>> groupedByDate = {};
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          final weekAgo = today.subtract(const Duration(days: 7));

          for (var t in filteredTrans) {
            final transDate = DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day);
            String label;
            
            if (transDate == today) {
              label = 'Hari Ini';
            } else if (transDate == yesterday) {
              label = 'Kemarin';
            } else if (transDate.isAfter(weekAgo)) {
              label = 'Minggu Ini';
            } else {
              label = '${_getMonthName(t.timestamp.month)} ${t.timestamp.year}';
            }
            
            if (!groupedByDate.containsKey(label)) {
              groupedByDate[label] = [];
            }
            groupedByDate[label]!.add(t);
          }
          
          // Sort groups: Hari Ini, Kemarin, Minggu Ini, then by month
          final sortedKeys = groupedByDate.keys.toList();
          sortedKeys.sort((a, b) {
            const order = ['Hari Ini', 'Kemarin', 'Minggu Ini'];
            final aIndex = order.indexOf(a);
            final bIndex = order.indexOf(b);
            if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
            if (aIndex != -1) return -1;
            if (bIndex != -1) return 1;
            return b.compareTo(a); // Reverse chronological for months
          });

          return Column(
            children: [
              // Summary Cards
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Total $currentYear',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Utils.formatCurrency(totalThisYear),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Tagihan Nanti',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Utils.formatCurrency(tagihanNanti),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Lunas'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Menunggu'),
                  ],
                ),
              ),

              // Timeline List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  children: sortedKeys.map((key) {
                    final transactions = groupedByDate[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            key,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...transactions.map((t) => _buildTransactionItem(t)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransaksiModel t) {
    Color statusColor = AppColors.grey;
    String statusText = 'Menunggu';
    IconData statusIcon = Icons.pending;

    if (t.status == 'sukses') {
      statusColor = AppColors.success;
      statusText = 'Lunas';
      statusIcon = Icons.check_circle;
    } else if (t.status == 'gagal') {
      statusColor = AppColors.danger;
      statusText = 'Gagal';
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForIuran(t.deskripsi).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForIuran(t.deskripsi),
              color: _getColorForIuran(t.deskripsi),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.deskripsi,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${t.timestamp.day} ${_getMonthName(t.timestamp.month)} ${t.timestamp.year}',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.grey)),
                    Text(
                      '${t.timestamp.hour.toString().padLeft(2, '0')}:${t.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Utils.formatCurrency(t.uang),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForIuran(String desc) {
    if (desc.toLowerCase().contains('keamanan')) return Icons.security;
    if (desc.toLowerCase().contains('kebersihan')) {
      return Icons.cleaning_services;
    }
    if (desc.toLowerCase().contains('sampah')) return Icons.delete;
    if (desc.toLowerCase().contains('lingkungan')) return Icons.nature;
    if (desc.toLowerCase().contains('air')) return Icons.water_drop;
    if (desc.toLowerCase().contains('renovasi')) return Icons.construction;
    return Icons.receipt;
  }

  Color _getColorForIuran(String desc) {
    if (desc.toLowerCase().contains('keamanan')) return AppColors.info;
    if (desc.toLowerCase().contains('kebersihan')) return AppColors.warning;
    if (desc.toLowerCase().contains('sampah')) return AppColors.danger;
    if (desc.toLowerCase().contains('lingkungan')) return AppColors.success;
    if (desc.toLowerCase().contains('renovasi')) return const Color(0xFFFF6B6B);
    return AppColors.primary;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}

// ========== PEMBAYARAN SCREEN (Revised for Bulk Payment) ==========
class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  
  // State for Selection
  final Set<String> _selectedIuranIds = {};
  List<IuranModel> _allIuran = [];
  bool _isLoading = false;
  String _selectedMethod = 'va';

  Set<String> _paidIuranIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {});
      _checkPaidStatus();
    }
  }

  void _checkPaidStatus() async {
    if (_currentUser == null) return;
    
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Get transactions just once to check status
    final trans = await _fs.getUserTransaksi(_currentUser!.id).first;
    
    final paidIds = trans.where((t) {
      // Must be pemasukan
      if (t.tipe != 'pemasukan') return false;
      
      // Status sukses or menunggu (don't allow paying again if pending)
      if (t.status == 'gagal') return false;
      
      // Check date/periode
      final tDate = t.timestamp;
      return tDate.month == currentMonth && tDate.year == currentYear;
    }).map((t) => t.iuranId).where((id) => id != null).cast<String>().toSet();

    if (mounted) {
      setState(() {
        _paidIuranIds = paidIds;
      });
    }
  }
  
  void _toggleSelection(String id) {
    if (_paidIuranIds.contains(id)) return; // Prevent selection if paid
    setState(() {
      if (_selectedIuranIds.contains(id)) {
        _selectedIuranIds.remove(id);
      } else {
        _selectedIuranIds.add(id);
      }
    });
  }

  void _selectAll() {
    // Select only unpaid
    final available = _allIuran.where((i) => !_paidIuranIds.contains(i.id)).toList();
    
    setState(() {
      if (_selectedIuranIds.length == available.length && available.isNotEmpty) {
        _selectedIuranIds.clear();
      } else {
        _selectedIuranIds.clear();
        _selectedIuranIds.addAll(available.map((e) => e.id));
      }
    });
  }

  int get _totalAmount {
    int total = 0;
    for (var iuran in _allIuran) {
      if (_selectedIuranIds.contains(iuran.id)) {
        total += iuran.harga;
      }
    }
    return total;
  }

  File? _buktiBayarFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _buktiBayarFile = File(image.path);
      });
    }
  }

  void _processPayment() async {
    if (_currentUser == null || _selectedIuranIds.isEmpty) return;

    if (_buktiBayarFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Harap upload bukti pembayaran"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedItems = _allIuran.where((i) => _selectedIuranIds.contains(i.id)).toList();
      
      // Upload Bukti
      String? buktiUrl;
      final supabase = SupabaseService();
      
      // Langsung coba upload tanpa test connection (karena ping google sering gagal di emulator/jaringan tertentu)
      buktiUrl = await supabase.uploadImage(_buktiBayarFile!);
      
      if (buktiUrl == null) {
        // Jika return null, berarti ada error di catch block services
        throw "Gagal upload image. Pastikan koneksi stabil.";
      }

      await _fs.bayarMultiIuran(
        _currentUser!,
        selectedItems,
        _selectedMethod,
        buktiUrl: buktiUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pembayaran Berhasil Dikirim!"), backgroundColor: Colors.green),
        );
        // Reset stack to main screen to avoid any back stack corruption
         Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserMainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("❌ Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Pembayaran Iuran'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // List Iuran
          Expanded(
            child: StreamBuilder<List<IuranModel>>(
              stream: _fs.getIuranList(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            "Gagal memuat data.\n${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text("Coba Lagi"),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada tagihan iuran saat ini."));
                }

                _allIuran = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Header Option: Select All
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedIuranIds.length == _allIuran.length && _allIuran.isNotEmpty,
                            onChanged: (val) => _selectAll(),
                            activeColor: AppColors.primary,
                          ),
                          const Text("Pilih Semua Tagihan", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._allIuran.map((iuran) => _buildIuranItem(iuran)),
                    
                    const SizedBox(height: 20),
                    // Bukti Pembayaran
                    const Text(
                      'Bukti Pembayaran',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _buktiBayarFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_buktiBayarFile!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text("Tap untuk upload bukti", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    // Metode Pembayaran (Simplified)
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentMethod('va', Icons.account_balance, 'Virtual Account'),
                      const SizedBox(height: 8),
                      _buildPaymentMethod('ewallet', Icons.account_balance_wallet, 'E-Wallet'),
                  ],
                );
              },
            ),
          ),
          
          // Bottom Summary
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140), // Added bottom padding for floating navbar
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea( // Safe Area top/left/right mainly
              top: false, 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_selectedIuranIds.length} Item Dipilih", style: const TextStyle(color: Colors.grey)),
                      Text(
                        Utils.formatCurrency(_totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedIuranIds.isEmpty || _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Bayar Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIuranItem(IuranModel iuran) {
    bool isPaid = _paidIuranIds.contains(iuran.id);
    final isSelected = _selectedIuranIds.contains(iuran.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: isPaid 
           ? const Icon(Icons.check_circle, color: Colors.green)
           : Checkbox(
              value: isSelected,
              onChanged: (val) => _toggleSelection(iuran.id),
              activeColor: AppColors.primary,
            ),
        title: Text(
            iuran.nama, 
            style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isPaid ? Colors.grey : Colors.black
            )
        ),
        subtitle: isPaid 
            ? const Text("Lunas bulan ini", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))
            : Text(iuran.deskripsi, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          Utils.formatCurrency(iuran.harga),
          style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: isPaid ? Colors.grey : AppColors.dark
          ),
        ),
        onTap: isPaid ? null : () => _toggleSelection(iuran.id),
      ),
    );
  }

  Widget _buildPaymentMethod(String id, IconData icon, String label) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}



// ========== PROFILE SCREEN (Gambar 2) ==========
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _fs = FirestoreService();
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
               if (_currentUser == null) return;
               final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: _currentUser!)));
               if (refresh == true) {
                 _loadUser();
               }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160), // Support Floating Navbar
        child: Column(
          children: [
            // Header Section
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Header Background Wavy
                ClipPath(
                  clipper: ProfileWaveClipper(),
                  child: Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF00796B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                
                // Content
                Positioned(
                  top: 100,
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10, 
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _currentUser?.role == 'admin' 
                              ? const AssetImage('assets/admin_avatar.png') 
                              : (_currentUser?.photoUrl != null && _currentUser!.photoUrl!.isNotEmpty 
                                  ? NetworkImage(_currentUser!.photoUrl!) as ImageProvider
                                  : null),
                          child: _currentUser?.role != 'admin' 
                             ? (_currentUser?.photoUrl != null && _currentUser!.photoUrl!.isNotEmpty
                                 ? null // Background image handles it
                                 : Text(
                                    _currentUser?.nama.isNotEmpty == true ? _currentUser!.nama[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                                   ))
                             : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentUser?.nama ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // Changed for better visibility on white card if overlap, but here it is below header
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentUser?.role == 'admin' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (_currentUser?.role ?? 'warga').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                             color: _currentUser?.role == 'admin' ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 80), // Space for the overlapping content
            
            // Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   // Personal Info Card
                   _buildSectionTitle('INFORMASI PRIBADI'),
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       children: [
                          _buildModernInfoRow(Icons.email_outlined, 'Email', _currentUser?.email ?? '-'),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernInfoRow(Icons.phone_outlined, 'No. Handphone', _currentUser?.noHp.isNotEmpty == true ? _currentUser!.noHp : '-'),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernInfoRow(Icons.home_work_outlined, 'Blok / Rumah', 
                              (_currentUser?.blok.isNotEmpty == true || _currentUser?.noRumah.isNotEmpty == true) 
                              ? '${_currentUser?.blok} / ${_currentUser?.noRumah}' 
                              : '-'),
                        ],
                     ),
                   ),
                   
                   const SizedBox(height: 24),
                   
                   // Settings Card
                   _buildSectionTitle('PENGATURAN'),
                   Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 4),
                         ),
                       ],
                     ),
                     child: Column(
                       children: [
                         _buildModernMenuTile(Icons.lock_outline, 'Ubah Kata Sandi', Colors.orange, () => _showChangePasswordDialog(context)),
                         const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernMenuTile(Icons.notifications_outlined, 'Notifikasi', Colors.blue, 
                             () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          _buildModernMenuTile(Icons.help_outline, 'Bantuan', Colors.purple, () => _showHelpDialog(context)),
                       ],
                     ),
                   ),

                   const SizedBox(height: 30),
                   
                   // Logout
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Keluar Aplikasi?'),
                              content: const Text('Anda harus login kembali untuk mengakses akun ini.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Keluar", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          
                          if (confirm == true && mounted) {
                             await _auth.logout();
                             Navigator.of(context).pushAndRemoveUntil(
                               MaterialPageRoute(builder: (_) => const LoginScreen()),
                               (route) => false,
                             );
                          }
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.white,
                         foregroundColor: Colors.red,
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                           side: const BorderSide(color: Colors.red, width: 1),
                         ),
                       ),
                       child: const Text('Keluar Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey[700], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernMenuTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  // Placeholder for _showChangePasswordDialog
  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Kata Sandi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Kata Sandi Lama"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Kata Sandi Baru"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (oldPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty) return;
              
              // Validate new password strength
              final error = SecurityUtils.validatePassword(newPassCtrl.text);
              if (error != null) {
                MessageHelper.showWarning(context, error);
                return;
              }

              // Verify old password (hash comparison)
              final oldHash = SecurityUtils.hashPassword(oldPassCtrl.text);
              
              // Support old plain passwords too for legacy
              bool isMatch = false;
              if (_currentUser!.password == oldPassCtrl.text) {
                isMatch = true; 
              } else if (_currentUser!.password == oldHash) {
                isMatch = true;
              }

              if (isMatch) {
                 MessageHelper.showLoading(context, message: 'Mengupdate password...');
                 
                 final newHash = SecurityUtils.hashPassword(newPassCtrl.text);
                 await _fs.updateUserProfile(_currentUser!.id, nama: _currentUser!.nama, email: _currentUser!.email, password: newHash);
                 
                 if (mounted) {
                   MessageHelper.hideLoading(context);
                   Navigator.pop(ctx);
                   MessageHelper.showSuccess(context, "✅ Password berhasil diubah!");
                 }
              } else {
                 MessageHelper.showError(context, "❌ Password lama salah!");
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.help_outline, color: Colors.blue), SizedBox(width: 8), Text('Bantuan')]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jika mengalami kendala, hubungi pengurus RT:'),
            SizedBox(height: 16),
            Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Pak RT (0812-3456-7890)')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Bendahara (0812-9876-5432)')]),
            SizedBox(height: 16),
            Text('Email Admin: admin@bukit.com', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup")),
        ],
      ),
    );
  }
}

class PengaduanScreen extends StatefulWidget {
  const PengaduanScreen({super.key});

  @override
  State<PengaduanScreen> createState() => _PengaduanScreenState();
}

class _PengaduanScreenState extends State<PengaduanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Info Warga'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            'Jadwal Pengambilan Sampah',
            'Setiap hari Selasa & Jumat, pukul 08:00 WIB.',
            Icons.delete_outline,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Jadwal Ronda Malam',
            'Silakan cek jadwal ronda di pos satpam atau grup WhatsApp warga.',
            Icons.security,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Kontak Darurat',
            'Satpam: 0812-3456-7890\nKetua RT: 0812-9876-5432',
            Icons.phone_in_talk,
            Colors.red,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur Buat Pengaduan segera hadir!')),
          );
        },
        label: const Text('Buat Pengaduan'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
