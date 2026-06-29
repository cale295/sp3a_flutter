import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../ocr/camera_scan_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/tagihan_provider.dart';
import '../../providers/pencatatan_provider.dart';

class PetugasDashboard extends ConsumerStatefulWidget {
  const PetugasDashboard({super.key});

  @override
  ConsumerState<PetugasDashboard> createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends ConsumerState<PetugasDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      const _PelangganListTab(),
      const _PaymentStatusTab(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SP3A Petugas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  Text(
                    authState.user?.namaLengkap ?? 'Petugas Lapangan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textDarkSecondary.withAlpha(153) : AppColors.textLightSecondary.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textDarkSecondary.withAlpha(128) : AppColors.textLightSecondary.withAlpha(128),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded, size: 22),
              activeIcon: Icon(Icons.people_rounded, size: 22),
              label: 'Pelanggan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined, size: 22),
              activeIcon: Icon(Icons.receipt_long_rounded, size: 22),
              label: 'Status Bayar',
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: DAFTAR PELANGGAN
// ==========================================
class _PelangganListTab extends ConsumerStatefulWidget {
  const _PelangganListTab();

  @override
  ConsumerState<_PelangganListTab> createState() => _PelangganListTabState();
}

class _PelangganListTabState extends ConsumerState<_PelangganListTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ──────────────── Numeric Input Dialog with OCR ────────────────
  void _showInputMeteranDialog(BuildContext context, UserModel customer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final angkaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    XFile? capturedImage;
    String? ocrStatusText;
    bool isOcrLoading = false;
    final now = DateTime.now();
    final bulanLabel = DateFormat('MMMM yyyy', 'id_ID').format(now);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> openCameraScan() async {
              try {
                final result = await Navigator.push<(String, XFile)>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraScanScreen(),
                  ),
                );

                if (result != null) {
                  final (detectedNumber, photo) = result;
                  setSheetState(() {
                    capturedImage = photo;
                    if (detectedNumber.isNotEmpty) {
                      angkaController.text = detectedNumber;
                      ocrStatusText = "Angka terdeteksi, silakan periksa kembali";
                    } else {
                      ocrStatusText = "Gagal mendeteksi angka, masukkan secara manual";
                    }
                  });
                }
              } catch (e) {
                debugPrint("Error navigating to camera scan: $e");
                setSheetState(() {
                  ocrStatusText = "Gagal memproses gambar: $e";
                });
              }
            }

            final canSubmit = !isSubmitting &&
                !isOcrLoading &&
                angkaController.text.trim().isNotEmpty &&
                capturedImage != null;

            return Padding(
              // Push sheet above keyboard
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[700] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.speed_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Input Meteran',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Periode: $bulanLabel',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textDarkSecondary
                                            : AppColors.textLightSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Customer info chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withAlpha(8) : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.namaLengkap,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        customer.alamat,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textDarkSecondary
                                              : AppColors.textLightSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Camera/Photo Section (Moved above TextField)
                          Text(
                            'Foto Bukti Fisik Meteran',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (capturedImage == null)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                              label: const Text(
                                'Ambil Foto Meteran',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: openCameraScan,
                            )
                          else
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      File(capturedImage!.path),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withAlpha(153),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Colors.white),
                                      onPressed: () {
                                        setSheetState(() {
                                          capturedImage = null;
                                          ocrStatusText = null;
                                          isOcrLoading = false;
                                          angkaController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // OCR Status text below the image
                          if (isOcrLoading || ocrStatusText != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (isOcrLoading) ...[
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    ocrStatusText ?? '',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isOcrLoading
                                          ? (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                                          : AppColors.primary, // Water Blue
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Label
                          Text(
                            'Angka Meter Saat Ini (m³)',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Numeric field — large font for readability (fully editable)
                          TextFormField(
                            controller: angkaController,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            onChanged: (val) {
                              setSheetState(() {});
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                color: isDark
                                    ? AppColors.textDarkSecondary.withAlpha(80)
                                    : AppColors.textLightSecondary.withAlpha(80),
                              ),
                              suffixText: 'm³',
                              suffixStyle: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.inputBgDark
                                  : AppColors.inputBgLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Angka meter tidak boleh kosong';
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed < 0) {
                                return 'Masukkan angka yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan angka yang tertera pada meteran air pelanggan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textLightSecondary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Submit button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.withAlpha(80),
                                disabledForegroundColor: Colors.grey,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_rounded, size: 20),
                              label: Text(
                                isSubmitting ? 'Menyimpan & Mengunggah...' : 'Simpan & Hitung Tagihan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              onPressed: canSubmit
                                  ? () async {
                                      if (!formKey.currentState!.validate()) return;

                                      setSheetState(() => isSubmitting = true);

                                      final angka = int.parse(angkaController.text.trim());
                                      final authState = ref.read(authProvider);
                                      final petugasId = authState.user?.id ?? 'unknown';

                                      final scaffoldMsg = ScaffoldMessenger.of(context);
                                      try {
                                        await ref
                                            .read(meteranServiceProvider)
                                            .petugasInputMeter(
                                              pelangganId: customer.id,
                                              dicatatOlehId: petugasId,
                                              periodeBulan: now.month,
                                              periodeTahun: now.year,
                                              angkaMeter: angka,
                                              imageFile: capturedImage!,
                                            );

                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }

                                        // Refresh list & bills
                                        ref.invalidate(pelangganWithStatusProvider);
                                        ref.invalidate(allBillsProvider);

                                        scaffoldMsg.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Meteran ${customer.namaLengkap} berhasil dicatat dan tagihan dibuat.',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppColors.success,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                      } catch (e) {
                                        setSheetState(() => isSubmitting = false);
                                        scaffoldMsg.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.error_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Gagal menyimpan: $e',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppColors.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pelangganAsync = ref.watch(pelangganWithStatusProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nama atau alamat...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textDarkSecondary.withAlpha(128) : AppColors.textLightSecondary.withAlpha(128),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),

          // Horizontal Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Rumah Tangga', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Bisnis', isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Pelanggan Air Aktif',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: pelangganAsync.when(
              data: (list) {
                final filtered = list.where((item) {
                  final user = item.pelanggan;
                  final matchesSearch = user.namaLengkap.toLowerCase().contains(_searchQuery) ||
                      user.alamat.toLowerCase().contains(_searchQuery);

                  final matchesCategory = _selectedCategory == 'Semua' ||
                      (_selectedCategory == 'Rumah Tangga' && user.tipePelanggan == TipePelanggan.rumahTangga) ||
                      (_selectedCategory == 'Bisnis' && user.tipePelanggan == TipePelanggan.bisnis);

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Pelanggan tidak ditemukan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(pelangganWithStatusProvider);
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final statusModel = filtered[index];
                      final customer = statusModel.pelanggan;
                      final sudahDicatat = statusModel.hasPetugasReading;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Row 1: Name + Badges ─────────────────────
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.namaLengkap,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.alamat,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? AppColors.textDarkSecondary
                                                : AppColors.textLightSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: customer.tipePelanggan.name.toUpperCase()),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ── Row 2: Status badge + Action button ───────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Status recording badge
                                  _buildRecordingBadge(sudahDicatat),
                                  // Action button — wrapped in its own Material context
                                  // to prevent nested InkWell conflicts with CustomCard
                                  if (sudahDicatat)
                                    _buildDisabledButton()
                                  else
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          _showInputMeteranDialog(context, customer);
                                        },
                                        child: Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                              SizedBox(width: 6),
                                              Text(
                                                'Input Meteran',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error memuat pelanggan: $err',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Green "Sudah Dicatat" or Gray "Belum Dicatat" badge
  Widget _buildRecordingBadge(bool sudahDicatat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sudahDicatat ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sudahDicatat ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: sudahDicatat ? const Color(0xFF137333) : const Color(0xFF5F6368),
          ),
          const SizedBox(width: 4),
          Text(
            sudahDicatat ? 'Sudah Dicatat' : 'Belum Dicatat',
            style: TextStyle(
              color: sudahDicatat ? const Color(0xFF137333) : const Color(0xFF5F6368),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// A visually disabled version of the Input button shown when already recorded
  Widget _buildDisabledButton() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 15, color: Colors.grey),
          SizedBox(width: 6),
          Text(
            'Input Meteran',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(31) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: MONITOR STATUS PEMBAYARAN
// ==========================================
class _PaymentStatusTab extends ConsumerStatefulWidget {
  const _PaymentStatusTab();

  @override
  ConsumerState<_PaymentStatusTab> createState() => _PaymentStatusTabState();
}

class _PaymentStatusTabState extends ConsumerState<_PaymentStatusTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pelangganAsync = ref.watch(pelangganListProvider);
    final billsAsync = ref.watch(allBillsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nama atau alamat...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textDarkSecondary.withAlpha(128) : AppColors.textLightSecondary.withAlpha(128),
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Status Pembayaran Pelanggan',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Status tagihan aktif masing-masing pelanggan.',
            style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: pelangganAsync.when(
              data: (pelangganList) {
                return billsAsync.when(
                  data: (billsList) {
                    final filtered = pelangganList.where((user) {
                      return user.namaLengkap.toLowerCase().contains(_searchQuery) ||
                          user.alamat.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('Pelanggan tidak ditemukan.', style: TextStyle(fontSize: 13, color: Colors.grey)));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(pelangganListProvider);
                        ref.invalidate(allBillsProvider);
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];

                          // Find latest bill for this customer
                          final customerBills = billsList.where((b) => b.pelangganId == customer.id).toList();

                          String statusLabel = 'Belum Ada Tagihan';
                          if (customerBills.isNotEmpty) {
                            statusLabel = customerBills.first.statusTagihan.dbValue;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.namaLengkap,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: -0.2),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.alamat,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.tipePelanggan.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.textDarkSecondary.withAlpha(128) : AppColors.textLightSecondary.withAlpha(128),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: statusLabel),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading bills: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading customers: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
