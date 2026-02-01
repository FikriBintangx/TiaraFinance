import 'package:tiara_fin/notification_service.dart';
import 'package:tiara_fin/models.dart';

/// Nih asisten buat munculin notif biar user peka
/// 
/// Catetan: Ini cuman helper santuy, kalo mau yang ribet pake service sebelah (services.dart)
/// yang connect ke Firestore.
class NotificationHelper {
  static final NotificationService _notifService = NotificationService();

  /// Munculin notif lokal kalo pembayaran dah di-approve
  static Future<void> notifyPaymentApproved(TransaksiModel transaksi) async {
    await _notifService.showNotification(
      title: '✅ Pembayaran Disetujui',
      body: 'Pembayaran ${transaksi.deskripsi} sebesar ${Utils.formatCurrency(transaksi.uang)} telah disetujui.',
      data: {
        'type': 'payment_approved',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Munculin notif lokal kalo pembayaran ditolak (ups)
  static Future<void> notifyPaymentRejected(TransaksiModel transaksi) async {
    await _notifService.showNotification(
      title: '❌ Pembayaran Ditolak',
      body: 'Pembayaran ${transaksi.deskripsi} ditolak. Silakan hubungi bendahara.',
      data: {
        'type': 'payment_rejected',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Munculin notif lokal ada duit masuk (buat admin)
  static Future<void> notifyNewPayment(TransaksiModel transaksi, String userName) async {
    await _notifService.showNotification(
      title: '💰 Pembayaran Baru',
      body: '$userName melakukan pembayaran ${transaksi.deskripsi}',
      data: {
        'type': 'new_payment',
        'transaksiId': transaksi.id,
      },
    );
  }

  /// Munculin notif lokal tagihan baru
  static Future<void> notifyNewIuran(IuranModel iuran) async {
    await _notifService.showNotification(
      title: '📢 Iuran Baru',
      body: '${iuran.nama} - ${Utils.formatCurrency(iuran.harga)}',
      data: {
        'type': 'new_iuran',
        'iuranId': iuran.id,
      },
    );
  }

  /// Pengingat bayar utang (eh iuran)
  static Future<void> notifyPaymentReminder(String iuranName) async {
    await _notifService.showNotification(
      title: '⏰ Pengingat Pembayaran',
      body: 'Jangan lupa bayar $iuranName sebelum tanggal jatuh tempo!',
      data: {
        'type': 'payment_reminder',
        'message_gaul': 'Ayo dong bayar, admin butuh healing nih',
      },
    );
  }
}

/// Helper buat format-format (biar rapi)
class Utils {
  static String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
