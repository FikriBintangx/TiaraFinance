import 'package:tiara_fin/screens/notification_screen.dart';
import 'package:tiara_fin/widgets/wavy_navbar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:tiara_fin/screens/auth_screens.dart'; // Utk logout nav
import 'package:tiara_fin/screens/user_screens.dart'; // Utk reuse ProfileScreen
import 'package:tiara_fin/screens/user_detail_screen.dart'; // New Import
// import 'package:printing/printing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiara_fin/screens/forum_screen.dart';
import 'package:tiara_fin/screens/admin_features.dart';

// --- ADMIN MAIN ---
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});
  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _idx = 0;
  String? _role;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  void _loadRole() async {
    final user = await _auth.getCurrentUser();
    if (mounted) {
      setState(() {
        _role = user?.role;
      });
    }
  }

  List<Widget> get _screens {
    if (_role == 'ketua_rt') {
       // Ketua RT: Dashboard, Laporan Transaksi (ReadOnly), User List, Profile
       // Hide "Kelola Iuran"
       return [
         const AdminDashboardScreen(),
         const AdminTransaksiScreen(), // Ensure this screen handles readonly/actions inside if needed, or create separate if strict
         const AdminUserScreen(), // Laporan Warga
         const AdminProfileScreen(),
       ];
    }
    // Default Admin
    return [
      const AdminDashboardScreen(),
      const AdminTransaksiScreen(),
      const AdminIuranScreen(),
      const AdminUserScreen(),
      const AdminProfileScreen(),
    ];
  }



  @override
  Widget build(BuildContext context) {
    if (_role == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Safety check idx if role changes/hot reload
    if (_idx >= _screens.length) _idx = 0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _screens[_idx],
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: WavyBottomBar(
                selectedIndex: _idx,
                items: _getNavIcons(),
                onItemSelected: (i) => setState(() => _idx = i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<IconData> _getNavIcons() {
    if (_role == 'ketua_rt') {
      return [
        Icons.dashboard_rounded,
        Icons.list_alt_rounded,
        Icons.people_rounded,
        Icons.person_rounded,
      ];
    }
    // Admin Default
    return [
       Icons.dashboard_rounded,
       Icons.list_alt_rounded,
       Icons.payment_rounded,
       Icons.people_rounded,
       Icons.person_rounded,
    ];
  }
}

// ========== Wavy Clipper (Copied for Admin) ==========
class AdminWavyClipper extends CustomClipper<Path> {
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

// --- ADMIN DASHBOARD (Gambar 5) ---
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  final SupabaseService _supabase = SupabaseService();
  UserModel? _currentAdmin;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  void _loadAdmin() async {
    _currentAdmin = await _auth.getCurrentUser();
    setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    // Determine Menu Items based on Role
    final bool isKetuaRT = _currentAdmin?.role == 'ketua_rt';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light Blue-Grey commonly used in dashboards
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Fix overlap
        child: FloatingActionButton(
          onPressed: () => _showQuickActions(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 160), // Fix overlap with floating nav
        child: Column(
          children: [
            // Wavy Header Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Wavy Background
                ClipPath(
                  clipper: AdminWavyClipper(),
                  child: Container(
                    height: 240,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00796B), Color(0xFF004D40)], // Premium Green
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // 2. Header Content (Name & Greeting)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: _currentAdmin == null 
                      ? const SizedBox() 
                      : StreamBuilder<UserModel>(
                        stream: _fs.streamUser(_currentAdmin!.id),
                        builder: (context, snapshot) {
                          final user = snapshot.data ?? _currentAdmin!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                        ? CachedNetworkImageProvider(user.photoUrl!)
                                        : null,
                                    child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                        ? const Icon(Icons.person, color: AppColors.primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Halo, ${user.nama}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user.role == 'ketua_rt' ? 'Ketua RT' : 'Administrator',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                          );
                        }
                      ),
                  ),
                  ),

                
                // 3. Stats Card Overlapping
                Padding(
                  padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
                  child: StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, snapshot) {
                      double totalKas = 0;
                      double pemasukan = 0;

                      if (snapshot.hasData) {
                        final list = snapshot.data!;
                        final masuk = list
                            .where((e) => e.tipe == 'pemasukan' && e.status == 'sukses')
                            .fold(0, (p, e) => p + e.uang);
                        final keluar = list
                            .where((e) => e.tipe == 'pengeluaran')
                            .fold(0, (p, e) => p + e.uang);
                        totalKas = (masuk - keluar).toDouble();
                        pemasukan = masuk.toDouble();
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                              // Total Kas
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Total Kas", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Text(
                                      Utils.formatCurrency(totalKas.toInt()),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("+12%", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 50, color: Colors.grey.shade300),
                              const SizedBox(width: 16),
                              // Pemasukan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Pemasukan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Text(
                                      Utils.formatCurrency(pemasukan.toInt()),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                     const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text("+8%", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // 4 Icon Menu Grid (Shortcuts to Tabs/Actions) - Custom for Admin/RT
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Column(
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       if (isKetuaRT) ...[
                          // Ketua RT Menu
                          Expanded(child: _buildMenuIcon(Icons.campaign, 'Info', AppColors.warning, () {
                            if (_currentAdmin != null) Navigator.push(context, MaterialPageRoute(builder: (_) => PengumumanListScreen(currentUser: _currentAdmin!)));
                          })),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMenuIcon(Icons.forum, 'Forum', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen())))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMenuIcon(Icons.analytics, 'Laporan', AppColors.purple, () => _exportPdf(context))),
                       ] else ...[
                          // Admin Menu
                          Expanded(child: _buildMenuIcon(Icons.note_add, 'Iuran', AppColors.primary, () => _showAddIuranDialog(context))),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMenuIcon(Icons.campaign, 'Info', AppColors.warning, () {
                            if (_currentAdmin != null) Navigator.push(context, MaterialPageRoute(builder: (_) => PengumumanListScreen(currentUser: _currentAdmin!)));
                          })),
                          const SizedBox(width: 10),
                          Expanded(child: _buildMenuIcon(Icons.forum, 'Forum', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForumDiskusiScreen())))),
                       ]
                     ],
                   ),
                   const SizedBox(height: 12),
                   // Second Row for overflow items (Admin)
                   if (!isKetuaRT)
                     Row(
                      children: [
                         Expanded(child: _buildMenuIcon(Icons.person_add, 'Warga', AppColors.info, () => _showAddUserDialog(context))),
                         const SizedBox(width: 10),
                         Expanded(child: _buildMenuIcon(Icons.analytics, 'Laporan', AppColors.purple, () => _exportPdf(context))),
                         const SizedBox(width: 10),
                         const Spacer(), // Balance spacing
                      ],
                     ),
                 ],
               ),
            ),

            const SizedBox(height: 24),

            // Aksi Cepat (Previously Grid, now maybe just a header or removed since we have the menu)
            // Let's keep "Aksi Cepat" as a secondary list or remove it if redundant?
            // The user asked to "samain sama menu dashboard warga" which implies the ICON GRID is the main menu.
            // So the above grid replaces the old "Aksi Cepat" buttons.
                       // Status Iuran Warga (Pie Chart) - Real Data
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<List<UserModel>>(
                stream: _fs.getUsers(),
                builder: (context, userSnap) {
                  return StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, transSnap) {
                      if (!userSnap.hasData || !transSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = userSnap.data!
                          .where((u) => u.role != 'admin') // Exclude admin
                          .toList();
                      final totalWarga = users.length;
                      
                      final now = DateTime.now();
                      final currentMonthTrans = transSnap.data!.where((t) {
                        return t.timestamp.month == now.month &&
                               t.timestamp.year == now.year &&
                               t.tipe == 'pemasukan' &&
                               t.status == 'sukses';
                      }).toList();

                      final paidUserIds = currentMonthTrans.map((t) => t.userId).toSet();
                      final lunasCount = users.where((u) => paidUserIds.contains(u.id)).length;
                      final belumCount = totalWarga - lunasCount;

                      // Fix division by zero if no users
                      return Column(
                        children: [
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status Iuran Warga (Bulan Ini)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              TextButton(onPressed: (){}, child: const Text('Detail', style: TextStyle(color: AppColors.primary)))
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2))],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 100, width: 100,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 0, centerSpaceRadius: 30,
                                      sections: [
                                        PieChartSectionData(
                                          color: AppColors.primary, 
                                          value: lunasCount.toDouble(), 
                                          radius: 15, 
                                          showTitle: false
                                        ),
                                        PieChartSectionData(
                                          color: AppColors.lightGrey, 
                                          value: belumCount.toDouble(), 
                                          radius: 15, 
                                          showTitle: false
                                        ),
                                      ]
                                    )
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendItem(AppColors.primary, 'Lunas', '$lunasCount Warga'),
                                      const SizedBox(height: 12),
                                      _buildLegendItem(AppColors.lightGrey, 'Belum Bayar', '$belumCount Warga'),
                                    ],
                                  )
                                )
                              ],
                            ),
                          )
                        ],
                      );
                    }
                  );
                }
              ),
            ),
            
            const SizedBox(height: 24),

            // Statistik Keuangan (Diagram Pemasukan vs Pengeluaran)
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statistik Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Text("6 Bulan Terakhir", style: TextStyle(color: Colors.blue, fontSize: 10)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
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

                        // Max Value for Y-Axis
                        double maxVal = 0;
                        for(var m in monthlyStats) {
                          if (m['income'] > maxVal) maxVal = m['income'];
                          if (m['expense'] > maxVal) maxVal = m['expense'];
                        }
                        if (maxVal == 0) maxVal = 100; // avoid zero

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
            
            // Aktivitas Terkini
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                    'Aktivitas Terkini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<TransaksiModel>>(
                    stream: _fs.getTransaksiList(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final recent = snapshot.data!.take(5).toList();
                      return Column(
                        children: recent.map((t) => _buildModernTransactionItem(t)).toList(),
                      );
                    },
                  ),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
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

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildModernTransactionItem(TransaksiModel t) {
    final isIncome = t.tipe == 'pemasukan';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncome ? AppColors.primary.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? AppColors.primary : AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  t.deskripsi,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${Utils.formatCurrency(t.uang)}',
            style: TextStyle(
              color: isIncome ? AppColors.primary : AppColors.danger,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.note_add, color: AppColors.primary),
                title: const Text('Catat Iuran Baru'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddIuranDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add, color: AppColors.primary),
                title: const Text('Tambah Warga'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign, color: AppColors.primary),
                title: const Text('Buat Pengumuman'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPengumumanDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                title: const Text('Catat Pemasukan Tunai'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPemasukanDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.money_off, color: AppColors.danger),
                title: const Text('Catat Pengeluaran'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddPengeluaranDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showAddPemasukanDialog(BuildContext context) {
    final jumlahCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Catat Pemasukan Tunai"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jumlahCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Jumlah Terima (Rp)",
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: "Dari Siapa / Keterangan",
                  hintText: "Contoh: Bpk. Budi (Iuran Sampah)",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              if (isUploading) ...[
                 const SizedBox(height: 16),
                 const LinearProgressIndicator(),
                 const Center(child: Text("Menyimpan...")),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                 if (jumlahCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi data")));
                   return;
                 }
                 
                 setState(() => isUploading = true);
                 
                 try {
                   final amount = int.parse(jumlahCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                   // Add 'manual_income' transaction type or reuse 'pemasukan' with 'sukses' status immediately
                   await _fs.addTransaksiManual(
                     userId: 'admin_manual', // Special ID for manual entry
                     userName: descCtrl.text, // User Name or Description
                     amount: amount,
                     type: 'pemasukan',
                     description: descCtrl.text,
                   );
                   
                   if (mounted) {
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Pemasukan Tercatat!"), backgroundColor: Colors.green));
                   }
                 } catch (e) {
                    setState(() => isUploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                 }
              },
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }

  void _showAddPengeluaranDialog(BuildContext context) {
    final jumlahCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    File? selectedImage;
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Catat Pengeluaran"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: jumlahCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Jumlah Pengeluaran (Rp)",
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Keterangan",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        selectedImage = File(image.path);
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Upload Struk/Bukti",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    "Mengupload bukti...",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (jumlahCtrl.text.isNotEmpty &&
                          descCtrl.text.isNotEmpty) {
                        setState(() => isUploading = true);

                        try {
                          String? uploadedUrl;
                          if (selectedImage != null) {
                            uploadedUrl = await _supabase.uploadImage(
                              selectedImage!,
                            );
                          }

                          if (_currentAdmin != null) {
                            await _fs.tambahPengeluaranAdmin(
                              _currentAdmin!.id,
                              _currentAdmin!.nama,
                              int.parse(jumlahCtrl.text),
                              descCtrl.text,
                              buktiUrl: uploadedUrl,
                            );

                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "✅ Pengeluaran berhasil dicatat!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Gagal: $e")),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIuranDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Jenis Iuran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Iuran",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                await _fs.tambahIuran(
                  nameCtrl.text,
                  int.parse(priceCtrl.text),
                  descCtrl.text,
                );
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Iuran berhasil ditambahkan!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final noRumahCtrl = TextEditingController();
    final noHpCtrl = TextEditingController(); // Added
    String selectedBlok = 'Q1';
    final List<String> blokList = ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Tambah Warga Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noHpCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "No. HP (WhatsApp)",
                    hintText: "Contoh: 628123456789",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBlok,
                        decoration: const InputDecoration(
                          labelText: 'Blok',
                          border: OutlineInputBorder(),
                        ),
                        items: blokList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedBlok = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: noRumahCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "No. Rumah",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Password akan dibuat otomatis:\n'NamaDepan' + 'Blok' + 'NoRumah' + '!'\nContoh: FikriQ1No12!",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty &&
                    emailCtrl.text.isNotEmpty &&
                    noRumahCtrl.text.isNotEmpty) {
                  // Auto Generate Password
                  final firstName = nameCtrl.text.split(
                    ' ',
                  )[0]; // Ambil kata pertama
                  final generatedPass =
                      "$firstName$selectedBlok${noRumahCtrl.text}!";

                  final error = await _auth.register(
                    nameCtrl.text,
                    emailCtrl.text,
                    generatedPass,
                    blok: selectedBlok,
                    noRumah: noRumahCtrl.text,
                    noHp: noHpCtrl.text,
                  );
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    if (error == null) {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("✅ Warga Ditambahkan"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${emailCtrl.text}"),
                              Text(
                                "Password: $generatedPass",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Harap simpan password ini atau minta warga segera menggantinya.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("❌ Gagal: $error"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Tambah"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPengumumanDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<XFile> selectedFiles = [];
    bool isUploading = false;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Buat Pengumuman"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Judul",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: "Isi Pengumuman",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final List<XFile> medias = await picker.pickMultipleMedia();
                    if (medias.isNotEmpty) {
                      setState(() {
                        if (medias.length > 10) {
                          selectedFiles = medias.sublist(0, 10);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Max 10 file, mengambil 10 pertama",
                              ),
                            ),
                          );
                        } else {
                          selectedFiles = medias;
                        }
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFiles.isEmpty
                              ? "Tap untuk Upload (Foto/Video)"
                              : "${selectedFiles.length} file dipilih",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selectedFiles.isEmpty
                                ? Colors.grey
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedFiles.take(5).map((e) {
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.grey,
                                ),
                              );
                            }).toList(),
                          ),
                          if (selectedFiles.length > 5)
                            Text(
                              "+ ${selectedFiles.length - 5} lainnya",
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    "Sedang mengupload...",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleCtrl.text.isNotEmpty &&
                          descCtrl.text.isNotEmpty) {
                        setState(() => isUploading = true);

                        List<String> urls = [];
                        try {
                          // Upload Files
                          for (var file in selectedFiles) {
                            final url = await _supabase.uploadImage(
                              File(file.path),
                            );
                            if (url != null) {
                              urls.add(url);
                            }
                          }

                          // Save to Firestore
                          await _fs.addPengumuman(
                            titleCtrl.text,
                            descCtrl.text,
                            _currentAdmin?.role == 'ketua_rt' ? "Ketua RT" : (_currentAdmin?.nama ?? "Admin"),
                            urls,
                          );

                          Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("✅ Pengumuman berhasil dipost!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => isUploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Gagal: $e")),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    // Show dialog to select filter
    String? selectedFilter = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Filter Laporan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExportOption(ctx, "Semua Transaksi", "semua", Icons.list),
            _buildExportOption(ctx, "Hanya Sukses", "sukses", Icons.check_circle, Colors.green),
            _buildExportOption(ctx, "Menunggu Verifikasi", "menunggu", Icons.hourglass_top, Colors.orange),
            _buildExportOption(ctx, "Gagal/Ditolak", "gagal", Icons.cancel, Colors.red),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        ],
      ),
    );

    if (selectedFilter == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menyiapkan PDF...")));
    }
    
    final snapshot = await _fs.getTransaksiList().first;
    try {
      await PdfService().exportLaporanBulanan(snapshot, filterStatus: selectedFilter);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal export: $e")));
      }
    }
  }

  Widget _buildExportOption(BuildContext ctx, String label, String value, IconData icon, [Color? color]) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.dark),
      title: Text(label),
      onTap: () => Navigator.pop(ctx, value),
    );
  }
}

// --- ADMIN TRANSAKSI (VERIFIKASI) ---
class AdminTransaksiScreen extends StatefulWidget {
  const AdminTransaksiScreen({super.key});

  @override
  State<AdminTransaksiScreen> createState() => _AdminTransaksiScreenState();
}

class _AdminTransaksiScreenState extends State<AdminTransaksiScreen> {
  String _searchQuery = '';
  String _filterStatus = 'semua';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari nama / deskripsi...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  // Debouncing: tunggu 300ms setelah user berhenti mengetik
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _searchQuery = val.toLowerCase());
                  });
                },
              )
            : const Text("Kelola Transaksi"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export Laporan Bulanan',
              onPressed: () async {
                 // ... existing export logic ...
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menyiapkan PDF...")),
                );
                final snapshot = await fs.getTransaksiList().first;
                try {
                  await PdfService().exportLaporanBulanan(snapshot, filterStatus: _filterStatus);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Gagal export: $e")));
                  }
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _filterStatus = value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'semua', child: Text('Semua')),
                const PopupMenuItem(value: 'menunggu', child: Text('Menunggu')),
                const PopupMenuItem(value: 'sukses', child: Text('Sukses')),
                const PopupMenuItem(value: 'gagal', child: Text('Gagal')),
              ],
            ),
          ],
        ],
      ),
      body: StreamBuilder<List<TransaksiModel>>(
        stream: fs.getTransaksiList(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var list = snapshot.data!;

          // Apply Status Filter
          if (_filterStatus != 'semua') {
            list = list.where((t) => t.status == _filterStatus).toList();
          }

          // Apply Search Filter
          if (_searchQuery.isNotEmpty) {
            list = list.where((t) {
              final name = t.userName.toLowerCase();
              final desc = t.deskripsi.toLowerCase();
              return name.contains(_searchQuery) || desc.contains(_searchQuery);
            }).toList();
          }

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada transaksi',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              Color statusColor = Colors.grey;
              if (item.status == 'sukses') statusColor = Colors.green;
              if (item.status == 'gagal') statusColor = Colors.red;
              if (item.status == 'menunggu') statusColor = Colors.orange;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailTransaksiScreen(transaksi: item),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(
                            item.tipe == 'pemasukan'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: item.tipe == 'pemasukan'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item.userName} - ${item.tipe.toUpperCase()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Utils.formatCurrency(item.uang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.deskripsi,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (item.status == 'sukses' &&
                                item.tipe == 'pemasukan')
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.green,
                                ),
                                tooltip: 'Kirim Kwitansi WA',
                                onPressed: () async {
                                  // Share receipt
                                  final text =
                                      "Kwitansi Digital Tiara Finance\n\n"
                                      "Telah terima dari: ${item.userName}\n"
                                      "Sejumlah: ${Utils.formatCurrency(item.uang)}\n"
                                      "Untuk: ${item.deskripsi}\n"
                                      "Tanggal: ${Utils.formatDateTime(item.timestamp)}\n"
                                      "Status: LUNAS\n\n"
                                      "Terima kasih.";

                                  // Encode for URL
                                  final url = Uri.parse(
                                    "https://wa.me/?text=${Uri.encodeComponent(text)}",
                                  );

                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tidak bisa membuka WhatsApp",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailTransaksiScreen extends StatelessWidget {
  final TransaksiModel transaksi;
  const DetailTransaksiScreen({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();
    Color statusColor = Colors.grey;
    if (transaksi.status == 'sukses') statusColor = Colors.green;
    if (transaksi.status == 'gagal') statusColor = Colors.red;
    if (transaksi.status == 'menunggu') statusColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Transaksi"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow('Nama', transaksi.userName),
                    const Divider(),
                    _detailRow('Jumlah', Utils.formatCurrency(transaksi.uang)),
                    const Divider(),
                    _detailRow('Tipe', transaksi.tipe.toUpperCase()),
                    const Divider(),
                    _detailRow('Deskripsi', transaksi.deskripsi),
                    const Divider(),
                    _detailRow(
                      'Tanggal',
                      Utils.formatDateTime(transaksi.timestamp),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            transaksi.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            if (transaksi.buktiGambar != null && transaksi.buktiGambar!.isNotEmpty) ...[
              const Text(
                "Bukti Pembayaran:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                   showDialog(context: context, builder: (ctx) => Dialog(
                     child: CachedNetworkImage(imageUrl: transaksi.buktiGambar!),
                   ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: transaksi.buktiGambar!,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (c, e, s) => Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 8),
                            Text("Gagal memuat gambar"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tidak ada bukti gambar",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (transaksi.status == 'menunggu')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tolak Transaksi?'),
                            content: const Text(
                              'Apakah Anda yakin ingin menolak transaksi ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Tolak'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await fs.updateStatusTransaksi(transaksi.id, 'gagal');
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("❌ Transaksi ditolak"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Tolak"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await fs.updateStatusTransaksi(transaksi.id, 'sukses');
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Transaksi disetujui!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Terima"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// --- ADMIN IURAN MANAGEMENT (NEW) ---
class AdminIuranScreen extends StatelessWidget {
  const AdminIuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Kelola Iuran", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<IuranModel>>(
        stream: fs.getIuranList(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final iurans = snap.data!;

          if (iurans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada iuran',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: iurans.length,
            itemBuilder: (c, i) {
              final iuran = iurans[i];
              return Slidable(
                key: ValueKey(iuran.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _showEditIuranDialog(context, iuran),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: 'Edit',
                      borderRadius: BorderRadius.circular(12),
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Iuran?'),
                            content: Text('Apakah Anda yakin ingin menghapus "${iuran.nama}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await fs.deleteIuran(iuran.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Iuran berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Hapus',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payment, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  iuran.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                Utils.formatCurrency(iuran.harga),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            iuran.deskripsi,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => _showEditIuranDialog(context, iuran),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text("Edit", style: TextStyle(color: Colors.blue, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hapus Iuran?'),
                                      content: Text(
                                        'Apakah Anda yakin ingin menghapus "${iuran.nama}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await fs.deleteIuran(iuran.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("✅ Iuran berhasil dihapus"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Angkat FAB agar tidak tertutup navbar
        child: FloatingActionButton.extended(
          onPressed: () => _showAddIuranDialog(context),
          icon: const Icon(Icons.add),
          label: const Text("Tambah Iuran"),
          backgroundColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  void _showAddIuranDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final FirestoreService fs = FirestoreService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Jenis Iuran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Iuran",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                await fs.tambahIuran(
                  nameCtrl.text,
                  int.parse(priceCtrl.text),
                  descCtrl.text,
                );
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Iuran berhasil ditambahkan!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text("Buat"),
          ),
        ],
      ),
    );
  }

  void _showEditIuranDialog(BuildContext context, IuranModel iuran) {
    final nameCtrl = TextEditingController(text: iuran.nama);
    final priceCtrl = TextEditingController(text: iuran.harga.toString());
    final descCtrl = TextEditingController(text: iuran.deskripsi);
    final FirestoreService fs = FirestoreService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Iuran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Iuran",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Harga",
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                await fs.updateIuran(
                  iuran.id,
                  nameCtrl.text,
                  int.parse(priceCtrl.text),
                  descCtrl.text,
                );
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Iuran berhasil diupdate!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}

// --- ADMIN USER LIST ---
// --- ADMIN USER LIST ---
class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final FirestoreService _fs = FirestoreService();
  String _filterStatus = 'Semua'; // Semua, Lunas, Belum Lunas

  Set<String> _getPaidUserIds(List<TransaksiModel> allTrans) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Filter transactions: Type=pemasukan, Status=sukses, Month matches
    final paidTrans = allTrans.where((t) {
      if (t.tipe != 'pemasukan' || t.status != 'sukses') return false;
      // Check date
      final tDate = t.timestamp;
      return tDate.month == currentMonth && tDate.year == currentYear;
    }).toList();

    return paidTrans.map((t) => t.userId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Warga"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) => setState(() => _filterStatus = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Semua', child: Text('Semua')),
              const PopupMenuItem(value: 'Lunas', child: Text('Sudah Bayar')),
              const PopupMenuItem(value: 'Belum Lunas', child: Text('Belum Bayar')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _fs.getUsers(),
        builder: (ctx, snapUsers) {
          if (!snapUsers.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<TransaksiModel>>(
            stream: _fs.getTransaksiList(),
            builder: (ctx, snapTrans) {
              if (!snapTrans.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapUsers.data!;
              final trans = snapTrans.data!;
              final paidIds = _getPaidUserIds(trans);

              // Filter users based on selection
              final filteredUsers = users.where((u) {
                if (u.role == 'admin') return false; // Hide admin from list usually? Or keep. Let's hide 'admin' role if filter is specific
                if (_filterStatus == 'Semua') return true;
                if (_filterStatus == 'Lunas') return paidIds.contains(u.id);
                if (_filterStatus == 'Belum Lunas') return !paidIds.contains(u.id);
                return true;
              }).toList();

              if (filteredUsers.isEmpty) {
                 return Center(child: Text("Tidak ada data user ($_filterStatus)"));
              }

              return Column(
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                     color: Colors.grey.shade100,
                     width: double.infinity,
                     child: Text(
                       "Menampilkan ${filteredUsers.length} warga (${_filterStatus})",
                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                     ),
                   ),
                   Expanded(
                     child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: filteredUsers.length,
                      itemBuilder: (c, i) {
                        final u = filteredUsers[i];
                        final isPaid = paidIds.contains(u.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              child: Text(
                                u.nama.isNotEmpty ? u.nama[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isPaid ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              u.nama,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email),
                                if (u.blok.isNotEmpty) Text("Blok ${u.blok} No ${u.noRumah}"),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid ? 'LUNAS' : 'BELUM',
                                    style: TextStyle(
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role,
                                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserDetailScreen(user: u),
                                ),
                              );
                            },
                          ),
                        );
                      },
                                       ),
                   ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}

// --- ADMIN PROFILE (reuse UserProfile) ---
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
