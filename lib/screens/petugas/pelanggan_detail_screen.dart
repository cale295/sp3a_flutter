import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../models/tagihan_with_pencatatan.dart';
import '../../providers/tagihan_provider.dart';
import '../../services/notification_service.dart';

class PelangganDetailScreen extends ConsumerStatefulWidget {
  final UserModel customer;

  const PelangganDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<PelangganDetailScreen> createState() => _PelangganDetailScreenState();
}

class _PelangganDetailScreenState extends ConsumerState<PelangganDetailScreen> {
  // Constant colors for Design System
  static const Color scaffoldBgColor = Color(0xFFFAFAFA);
  static const Color waterBlueColor = Color(0xFF0EA5E9);

  bool _isSending = false;
  int? _sendingBillId;

  // Month names in Indonesian
  final List<String> _listBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  Future<void> _sendReminderNotification(TagihanWithPencatatan billItem) async {
    final periodName = "${_listBulan[billItem.periodeBulan]} ${billItem.periodeTahun}";

    setState(() {
      _isSending = true;
      _sendingBillId = billItem.tagihan.id;
    });

    try {
      final notifier = ref.read(notificationServiceProvider);
      await notifier.sendReminder(
        pelangganId: widget.customer.id,
        periode: periodName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Peringatan pembayaran untuk periode $periodName berhasil dikirim!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            'Gagal Mengirim Peringatan',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.plusJakartaSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'OK',
                style: GoogleFonts.plusJakartaSans(
                  color: waterBlueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingBillId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(tagihanWithPencatatanProvider(widget.customer.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: waterBlueColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Pelanggan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Customer Profile Card ──────────────────────────────────
          Container(
            color: isDark ? AppColors.cardDark : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customer.namaLengkap,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.customer.tipePelanggan == TipePelanggan.rumahTangga
                                  ? 'Rumah Tangga'
                                  : 'Bisnis',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text(
                  'Alamat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkSecondary.withAlpha(150) : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customer.alamat,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Section Title: Billing History ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Riwayat Tagihan Bulanan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
          ),

          // ── Billing List ───────────────────────────────────────────────────
          Expanded(
            child: billsAsync.when(
              data: (bills) {
                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                              .withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat tagihan.',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final billItem = bills[index];
                    final bill = billItem.tagihan;
                    final periodName = "${_listBulan[billItem.periodeBulan]} ${billItem.periodeTahun}";
                    final double totalAmount = bill.totalTagihan + bill.totalDenda;

                    final isUnpaid = bill.statusTagihan.dbValue == 'belum_dibayar' ||
                        bill.statusTagihan.dbValue == 'belum_bayar';

                    final isThisBillSending = _isSending && _sendingBillId == bill.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Period Circle Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Billing metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      periodName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      currencyFormatter.format(totalAmount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                      ),
                                    ),
                                    if (bill.totalDenda > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '(Termasuk Denda: ${currencyFormatter.format(bill.totalDenda)})',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status & Reminder Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  StatusBadge(status: bill.statusTagihan.dbValue),
                                  if (isUnpaid) ...[
                                    const SizedBox(height: 10),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: _isSending
                                            ? null
                                            : () => _sendReminderNotification(billItem),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: waterBlueColor, width: 1.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isThisBillSending)
                                                const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: waterBlueColor,
                                                  ),
                                                )
                                              else
                                                const Icon(
                                                  Icons.notification_important_rounded,
                                                  color: waterBlueColor,
                                                  size: 13,
                                                ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ingatkan',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: waterBlueColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Gagal memuat riwayat tagihan: $err',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
