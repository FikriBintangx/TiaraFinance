import 'package:flutter/material.dart';
import 'package:tiara_fin/notification_service.dart';

/// Test screen untuk testing notifikasi
/// Akses: Tambahkan button di halaman manapun untuk buka screen ini
class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifikasi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await NotificationService().showNotification(
                  title: '💰 Test Pembayaran',
                  body: 'Ini adalah test notifikasi pembayaran',
                  data: {'type': 'payment'},
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi terkirim! Cek notification center')),
                  );
                }
              },
              child: const Text('Test Payment Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().showNotification(
                  title: '⚠️ Test Alert',
                  body: 'Ini adalah test notifikasi alert',
                  data: {'type': 'alert'},
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi terkirim! Cek notification center')),
                  );
                }
              },
              child: const Text('Test Alert Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().showNotification(
                  title: 'ℹ️ Test Info',
                  body: 'Ini adalah test notifikasi info',
                  data: {'type': 'info'},
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi terkirim! Cek notification center')),
                  );
                }
              },
              child: const Text('Test Info Notification'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tap button di atas untuk test notifikasi.\nNotifikasi akan muncul di notification center device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
