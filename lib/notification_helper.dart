import 'package:tiara_fin/notification_service.dart';
import 'package:tiara_fin/models.dart';

/// Helper functions untuk trigger notifications
class NotificationHelper {
  static final NotificationService _notifService = NotificationService();

  /// Notify user saat pembayaran berhasil diverifikasi
  static Future<void> notifyPaymentApproved(TransaksiModel transaksi) async {
    await _notifService.sendNotificationToUser(
      userId: transaksi.userId,
      title: '✅ Pembayaran Disetujui',
      body: 'Pembayaran ${transaksi.deskripsi} sebesar ${Utils.formatCurrency(transaksi.uang)} telah disetujui.',
      data: {
        'type': 'payment_approved',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Notify user saat pembayaran ditolak
  static Future<void> notifyPaymentRejected(TransaksiModel transaksi) async {
    await _notifService.sendNotificationToUser(
      userId: transaksi.userId,
      title: '❌ Pembayaran Ditolak',
      body: 'Pembayaran ${transaksi.deskripsi} ditolak. Silakan hubungi bendahara.',
      data: {
        'type': 'payment_rejected',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Notify admin saat ada pembayaran baru
  static Future<void> notifyNewPayment(TransaksiModel transaksi, String userName) async {
    await _notifService.sendNotificationToRole(
      role: 'admin',
      title: '💰 Pembayaran Baru',
      body: '$userName melakukan pembayaran ${transaksi.deskripsi}',
      data: {
        'type': 'new_payment',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Notify semua warga saat ada iuran baru
  static Future<void> notifyNewIuran(IuranModel iuran) async {
    await _notifService.sendNotificationToRole(
      role: 'user',
      title: '📢 Iuran Baru',
      body: '${iuran.nama} - ${Utils.formatCurrency(iuran.harga)}',
      data: {
        'type': 'new_iuran',
        'iuranId': iuran.id,
      },
    );
  }

  /// Notify warga saat mendekati jatuh tempo
  static Future<void> notifyPaymentReminder(String userId, String iuranName) async {
    await _notifService.sendNotificationToUser(
      userId: userId,
      title: '⏰ Pengingat Pembayaran',
      body: 'Jangan lupa bayar $iuranName sebelum tanggal jatuh tempo!',
      data: {
        'type': 'payment_reminder',
      },
    );
  }
}

/// Utils class untuk formatting
class Utils {
  static String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
