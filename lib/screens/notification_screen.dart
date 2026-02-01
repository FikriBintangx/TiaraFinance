import 'package:flutter/material.dart';

import 'package:tiara_fin/services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  String _userRole = 'warga';
  String _selectedFilter = 'all'; // all, payment, announcement, alert

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  void _loadRole() async {
    final user = await _auth.getCurrentUser();
    if (user != null) {
      setState(() {
        _userRole = user.role;
      });
    }
  }

  void _showNotificationDetail(NotificationModel notif) {
    // Mark as read
    _fs.markNotificationAsRead(notif.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getNotificationIcon(notif.type),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notif.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.body,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  Utils.formatDateTime(notif.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'payment':
        icon = Icons.payment;
        color = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
      actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _fs.getNotifications(_userRole),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final allNotifs = snapshot.data!;
              final unreadCount = allNotifs.where((n) => !n.isRead).length;
              
              if (unreadCount == 0) return const SizedBox();
              
              return Row(
                children: [
                   // Replace TextButton with PopupMenuButton for more options
                   PopupMenuButton<String>(
                     onSelected: (value) {
                       if (value == 'read_all') {
                          for (var n in allNotifs.where((n) => !n.isRead)) {
                            _fs.markNotificationAsRead(n.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua ditandai sudah dibaca")));
                       } else if (value == 'unread_all') {
                          for (var n in allNotifs) {
                            _fs.markNotificationAsUnread(n.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua ditandai belum dibaca")));
                       }
                     },
                     itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                       const PopupMenuItem<String>(
                         value: 'read_all',
                         child: Text('Tandai Semua Dibaca'),
                       ),
                       const PopupMenuItem<String>(
                         value: 'unread_all',
                         child: Text('Tandai Semua Belum Dibaca'),
                       ),
                     ],
                     child: const Padding(
                       padding: EdgeInsets.symmetric(horizontal: 8.0),
                       child: Row(
                         children: [
                           Text("Opsi", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                           Icon(Icons.arrow_drop_down, color: AppColors.primary),
                         ],
                       ),
                     ),
                   ),
                   Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount baru',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pembayaran', 'payment', icon: Icons.payment),
                const SizedBox(width: 8),
                _buildFilterChip('Pengumuman', 'announcement', icon: Icons.campaign),
                const SizedBox(width: 8),
                _buildFilterChip('Darurat', 'alert', icon: Icons.warning_amber),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _fs.getNotifications(_userRole),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var notifs = snapshot.data!;
                
                // Apply Filter
                if (_selectedFilter != 'all') {
                  notifs = notifs.where((n) => n.type == _selectedFilter).toList();
                }

                if (notifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                         const SizedBox(height: 16),
                         Text(
                           _selectedFilter == 'all' 
                              ? "Belum ada notifikasi" 
                              : "Tidak ada notifikasi kategori ini",
                           style: TextStyle(color: Colors.grey.shade600),
                         ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    return _buildNotifItem(notifs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon}) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? Colors.white : Colors.grey[600]
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildNotifItem(NotificationModel notif) {
    IconData icon;
    Color color;

    switch (notif.type) {
      case 'payment':
        icon = Icons.payment_rounded;
        color = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
        break;
      case 'announcement':
        icon = Icons.campaign_rounded;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications_active_rounded;
        color = Colors.blue;
    }

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.mark_email_unread, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as unread
          _fs.markNotificationAsUnread(notif.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ditandai belum dibaca")));
          return false; // Don't dismiss
        } 
        return true; // Delete
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Here we delete the notification
          _fs.deleteNotification(notif.id);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notifikasi dihapus")));
        }
      },
      child: InkWell(
        onTap: () => _showNotificationDetail(notif),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF0F9FF), // Light blue for unread
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notif.isRead ? Colors.grey.withValues(alpha: 0.1) : color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w800,
                              fontSize: 15,
                              color: notif.isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.body,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Utils.formatDateTime(notif.timestamp),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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
}
