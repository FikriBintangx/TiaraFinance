import 'package:flutter/material.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';
 // for AppColors
import 'package:tiara_fin/theme.dart';
import 'package:tiara_fin/screens/feature_screens.dart';

class ForumDiskusiScreen extends StatefulWidget {
  const ForumDiskusiScreen({super.key});

  @override
  State<ForumDiskusiScreen> createState() => _ForumDiskusiScreenState();
}

class _ForumDiskusiScreenState extends State<ForumDiskusiScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  UserModel? _currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  void _loadUser() async {
    _currentUser = await _auth.getCurrentUser();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only Ketua RT can verify/administer forum discussions. 
    // Bendahara (role 'admin') should currently function as a regular user in this context.
    bool isAdmin = _currentUser?.role == 'ketua_rt';

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Forum Diskusi Warga'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.dark,
        bottom: isAdmin
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: "Aktif"),
                  Tab(text: "Menunggu Verifikasi"),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddForumDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Buat Topik", style: TextStyle(color: Colors.white)),
      ),
      body: isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildForumList(status: 'approved'),
                _buildForumList(status: 'pending', isAdminView: true),
              ],
            )
          : _buildForumList(status: 'approved'),
    );
  }

  Widget _buildForumList({required String status, bool isAdminView = false}) {
    // Optimization: Only Admins need to fetch ALL data (to see pending). 
    // Regular users should only fetch 'approved' from DB to save bandwidth/security.
    // 'status' arg is used for client-side filtering of the stream result.
    
    // If we want 'approved' list:
    // - Admin: Fetch ALL (isAdmin=true), then filter filter(status=='approved')
    // - User: Fetch APPROVED (isAdmin=false), filter is redundant but fine.
    
    // If we want 'pending' list:
    // - Admin: Fetch ALL (isAdmin=true), filter(status=='pending')
    
    bool fetchAsAdmin = _currentUser?.role == 'ketua_rt';

    return StreamBuilder<List<ForumModel>>(
      stream: _fs.getForumDiskusi(isAdmin: fetchAsAdmin), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Terjadi kesalahan memuat data: ${snapshot.error}', textAlign: TextAlign.center),
          ));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPosts = snapshot.data!;
        final posts = allPosts.where((p) => p.status == status).toList();

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.playlist_add_check : Icons.forum_outlined, 
                  size: 64, color: Colors.grey[300]
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'pending' ? "Tidak ada diskusi menunggu." : "Belum ada diskusi aktif.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildForumItem(post, isAdminView);
          },
        );
      },
    );
  }

  Widget _buildForumItem(ForumModel post, bool isPendingView) {
    final isMe = post.authorId == _currentUser?.id;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForumChatScreen(forum: post, currentUser: _currentUser!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isMe ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3)) : null,
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isMe ? AppTheme.primary : Colors.grey.shade200, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isMe ? AppTheme.primary : Colors.grey.shade100,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Oleh ${post.authorName} • ${Utils.formatDateTime(post.createdAt)}",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (post.status == 'pending')
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                     child: const Text("Pending", style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold)),
                   )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMain, height: 1.5),
            ),
            const SizedBox(height: 16),
            
            // Like/Comment Count Indicator (Visual Only for now)
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text("Diskusi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (isPendingView) ...[
                  TextButton(
                    onPressed: () => _updateStatus(post, 'rejected'),
                    child: const Text("Tolak", style: TextStyle(color: AppTheme.danger)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateStatus(post, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                  ),
                ] else 
                   const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
              ],
            )
          ],
        ),
      ),
    );
  }

  void _updateStatus(ForumModel post, String status) async {
    try {
      if (status == 'approved') {
        await _fs.approveForum(post.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Diskusi Disetujui")));
      } else {
        await _fs.rejectForum(post.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diskusi Ditolak")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddForumDialog(BuildContext context) {
    if (_currentUser == null) return;
    
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.forum, color: AppColors.primary),
                SizedBox(width: 8),
                Text("Buat Diskusi Baru"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Judul Diskusi",
                    hintText: "Contoh: Kerja Bakti",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Detail Diskusi",
                    hintText: "Tuliskan detail...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                  Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                   child: const Row(
                     children: [
                       Icon(Icons.info_outline, size: 16, color: Colors.blue),
                       SizedBox(width: 8),
                       Expanded(child: Text("Diskusi perlu disetujui Ketua RT sebelum tampil ke publik.", style: TextStyle(fontSize: 11, color: Colors.blueGrey))),
                     ],
                   ),
                 )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                    return;
                  }
                  
                  setState(() => isSubmitting = true);
                  
                  try {
                    await _fs.requestForum(
                      _currentUser!.id,
                      _currentUser!.nama,
                      titleController.text.trim(),
                      contentController.text.trim(),
                    );
                    
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Permintaan diskusi terkirim! Menunggu verifikasi admin.")),
                      );
                    }
                  } catch (e) {
                     setState(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Kirim"),
              ),
            ],
          );
        }
      ),
    );
  }
}
