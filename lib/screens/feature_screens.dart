// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tiara_fin/models.dart';
import 'package:tiara_fin/services.dart';

// --- HELPER ---
String _formatTime(DateTime dt) {
  final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  return "${dt.day} ${months[dt.month-1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
}

// ==========================================
// 1. DETAIL PENGUMUMAN SCREEN
// ==========================================
class DetailPengumumanScreen extends StatefulWidget {
  final PengumumanModel pengumuman;
  final UserModel currentUser;

  const DetailPengumumanScreen({super.key, required this.pengumuman, required this.currentUser});

  @override
  State<DetailPengumumanScreen> createState() => _DetailPengumumanScreenState();
}

class _DetailPengumumanScreenState extends State<DetailPengumumanScreen> {
  final _commentCtrl = TextEditingController();
  final _fs = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-mark as viewed if not already
    if (!widget.pengumuman.viewers.contains(widget.currentUser.id)) {
      _fs.markPengumumanAsViewed(widget.pengumuman.id, widget.currentUser.id);
    }
  }

  void _kirimKomentar() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    await _fs.addPengumumanComment(
      widget.pengumuman.id, 
      widget.currentUser.id, 
      widget.currentUser.nama, 
      _commentCtrl.text.trim()
    );
    _commentCtrl.clear();
    setState(() => _isLoading = false);
  }

  void _showViewersDialog() async {
    // Show loading dialog then fetch users
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    );

    try {
      // Fetch all users stream/future (inefficient but works for small app)
      // We assume FirestoreService has getUsers stream, we take header
      final snap = await FirebaseFirestore.instance.collection('users').get();
      final allUsers = snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      
      final viewers = allUsers.where((u) => widget.pengumuman.viewers.contains(u.id)).toList();
      
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Dilihat oleh (${viewers.length})"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: viewers.isEmpty 
              ? const Center(child: Text("Belum ada yang melihat.")) 
              : ListView.builder(
                  itemCount: viewers.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: CircleAvatar(child: Text(viewers[i].nama[0].toUpperCase())),
                    title: Text(viewers[i].nama),
                    subtitle: Text(viewers[i].blok),
                  ),
                ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tutup"))],
        ),
      );
    } catch(e) {
      Navigator.pop(context); // Close loading in case of error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canViewReaders = ['admin', 'ketua_rt'].contains(widget.currentUser.role);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Stack(
            children: [
              ClipPath(
                clipper: FeatureWavyClipper(),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF009688), Color(0xFF00796B)]),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white), 
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 10),
                      Text(widget.pengumuman.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              if (canViewReaders)
                Positioned(
                  top: 50, right: 20,
                  child: IconButton(
                    onPressed: _showViewersDialog,
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    tooltip: "Lihat Pembaca",
                  ),
                ),
            ],
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Oleh: ${widget.pengumuman.authorName}", style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatTime(widget.pengumuman.date), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Image if any (Simple implementation)
                  if (widget.pengumuman.imageUrls.isNotEmpty)
                    Hero(
                      tag: widget.pengumuman.id,
                      child: Container(
                        height: 200, 
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(widget.pengumuman.imageUrls.first),
                            fit: BoxFit.cover,
                            onError: (_,__) => const Icon(Icons.broken_image)
                          )
                        ),
                      ),
                    ),

                  // Description
                  Text(
                    widget.pengumuman.description,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const Text("Komentar Warga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Comments Stream
                  StreamBuilder<List<CommentModel>>(
                    stream: _fs.getPengumumanComments(widget.pengumuman.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text("Gagal memuat komentar.");
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final comments = snapshot.data!;
                      if (comments.isEmpty) return const Text("Belum ada komentar. Jadilah yang pertama!", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0,2))]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(_formatTime(c.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c.content, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 60), // Space for input
                ],
              ),
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,-5))]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF009688),
                  child: IconButton(
                    icon: _isLoading ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading ? null : _kirimKomentar,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. FORUM CHAT SCREEN
// ==========================================
class ForumChatScreen extends StatefulWidget {
  final ForumModel forum;
  final UserModel currentUser;

  const ForumChatScreen({super.key, required this.forum, required this.currentUser});

  @override
  State<ForumChatScreen> createState() => _ForumChatScreenState();
}

class _ForumChatScreenState extends State<ForumChatScreen> {
  final _msgCtrl = TextEditingController();
  final _fs = FirestoreService();
  bool _isLoading = false;

  void _kirimPesan() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    
    // Check Status first (double usage check)
    if (widget.forum.status == 'pending' && widget.currentUser.role == 'user') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diskusi ini belum disetujui Ketua RT.")));
      return;
    }

    setState(() => _isLoading = true);
    await _fs.sendForumMessage(
      widget.forum.id, 
      widget.currentUser.id, 
      widget.currentUser.nama, 
      _msgCtrl.text.trim()
    );
    _msgCtrl.clear();
    setState(() => _isLoading = false);
  }

  void _updateStatus(String status) async {
    setState(() => _isLoading = true);
    if (status == 'approved') {
      await _fs.approveForum(widget.forum.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diskusi Disetujui!")));
    } else {
      await _fs.rejectForum(widget.forum.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diskusi Ditolak!")));
      Navigator.pop(context); // Close if rejected
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.currentUser.role == 'ketua_rt';
    bool isPending = widget.forum.status == 'pending';
    bool canChat = isAdmin || !isPending;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.forum.title, style: const TextStyle(fontSize: 18)),
            Text("oleh ${widget.forum.authorName}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Admin Moderation Banner
          if (isAdmin && isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[100],
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(child: Text("Diskusi ini menunggu persetujuan.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                  TextButton(onPressed: () => _updateStatus('rejected'), child: const Text("Tolak", style: TextStyle(color: Colors.red))),
                  ElevatedButton(
                    onPressed: () => _updateStatus('approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          
          if (!isAdmin && isPending)
             Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange[50],
              width: double.infinity,
              child: const Text("Menunggu verifikasi Ketua RT...", textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),

          // Deskripsi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Text(widget.forum.description, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: StreamBuilder<List<ForumMessageModel>>(
              stream: _fs.getForumMessages(widget.forum.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!;
                
                if (msgs.isEmpty) {
                  return const Center(child: Text("Belum ada obrolan. Mulai diskusi!", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true, // Chat style: newest at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index];
                    bool isMe = msg.senderId == widget.currentUser.id;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF009688) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0,1))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) 
                              Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                            if (!isMe) const SizedBox(height: 4),
                            Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                            const SizedBox(height: 4),
                            Text(_formatTime(msg.timestamp), 
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          if (canChat)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: "Tulis pesan...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF009688)), 
                    onPressed: _kirimPesan
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. CREATE PENGUMUMAN SCREEN (ADMIN)
// ==========================================
class CreatePengumumanScreen extends StatefulWidget {
  final UserModel currentUser;
  const CreatePengumumanScreen({super.key, required this.currentUser});

  @override
  State<CreatePengumumanScreen> createState() => _CreatePengumumanScreenState();
}

class _CreatePengumumanScreenState extends State<CreatePengumumanScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);
    await FirestoreService().addPengumuman(
      _titleCtrl.text, 
      _descCtrl.text, 
      widget.currentUser.role == 'ketua_rt' ? "Ketua RT" : widget.currentUser.nama, // Use formal title or name
      [] // No images for now
    );
    setState(() => _isLoading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pengumuman berhasil dibuat!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Pengumuman"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: "Judul Pengumuman",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Isi Pengumuman",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("PUBLIKASIKAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Reusable Clipper
class FeatureWavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width - (size.width / 4), size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
