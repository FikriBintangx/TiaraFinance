import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models_voting.dart';
import '../services.dart';

class EventListScreen extends StatelessWidget {
  final String currentUserId;
  final bool isAdmin;

  const EventListScreen({
    super.key,
    required this.currentUserId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateEventDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Event'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('event_date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs
              .map((doc) => EventModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kegiatan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol + untuk membuat kegiatan',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            );
          }

          // Separate upcoming and past events
          final now = DateTime.now();
          final upcomingEvents = events.where((e) => !e.isPast).toList();
          final pastEvents = events.where((e) => e.isPast).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcomingEvents.isNotEmpty) ...[
                const Text(
                  'Kegiatan Mendatang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...upcomingEvents.map((event) => _buildEventCard(context, event)),
                const SizedBox(height: 24),
              ],
              if (pastEvents.isNotEmpty) ...[
                const Text(
                  'Kegiatan Selesai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...pastEvents.map((event) => _buildEventCard(context, event, isPast: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, {bool isPast = false}) {
    final isAttending = event.attendees.contains(currentUserId);
    final daysUntil = event.eventDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              event: event,
              currentUserId: currentUserId,
              isAdmin: isAdmin,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.1)
                          : event.isToday
                              ? Colors.orange.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event,
                      color: isPast
                          ? Colors.grey
                          : event.isToday
                              ? Colors.orange
                              : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(event.eventDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (event.isToday && !isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'HARI INI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attendees.length} peserta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (!isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAttending
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAttending ? Icons.check_circle : Icons.circle_outlined,
                            size: 12,
                            color: isAttending ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAttending ? 'Hadir' : 'RSVP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAttending ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Buat Kegiatan Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Kegiatan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Tanggal'),
                    subtitle: Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Waktu'),
                    subtitle: Text(selectedTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul harus diisi')),
                    );
                    return;
                  }

                  final eventDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final event = EventModel(
                    id: '',
                    title: titleCtrl.text,
                    description: descCtrl.text,
                    eventDate: eventDateTime,
                    location: locationCtrl.text,
                    createdBy: currentUserId,
                    createdAt: DateTime.now(),
                    attendees: [],
                  );

                  await FirebaseFirestore.instance
                      .collection('events')
                      .add(event.toMap());

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Kegiatan berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Buat'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  final String currentUserId;
  final bool isAdmin;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.isAdmin,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<void> _toggleRSVP() async {
    final isAttending = widget.event.attendees.contains(widget.currentUserId);

    try {
      if (isAttending) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({
          'attendees': FieldValue.arrayRemove([widget.currentUserId]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .update({
          'attendees': FieldValue.arrayUnion([widget.currentUserId]),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAttending
                  ? '❌ Anda membatalkan kehadiran'
                  : '✅ Anda terdaftar sebagai peserta!',
            ),
            backgroundColor: isAttending ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kegiatan'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = EventModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          final isAttending = event.attendees.contains(widget.currentUserId);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image Placeholder
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.event,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date & Time
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Tanggal & Waktu',
                        DateFormat('EEEE, dd MMMM yyyy\nHH:mm WIB').format(event.eventDate),
                      ),
                      const SizedBox(height: 12),

                      // Location
                      _buildInfoRow(
                        Icons.location_on,
                        'Lokasi',
                        event.location,
                      ),
                      const SizedBox(height: 12),

                      // Attendees
                      _buildInfoRow(
                        Icons.people,
                        'Peserta',
                        '${event.attendees.length} orang terdaftar',
                      ),
                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // RSVP Button
                      if (!event.isPast)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _toggleRSVP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAttending ? Colors.orange : AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(isAttending ? Icons.cancel : Icons.check_circle),
                            label: Text(
                              isAttending ? 'Batalkan Kehadiran' : 'Saya Akan Hadir',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      if (event.isPast)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_busy, color: Colors.grey[700]),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Kegiatan telah selesai',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
