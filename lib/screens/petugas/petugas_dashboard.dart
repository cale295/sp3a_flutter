import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/tagihan_provider.dart';
import '../../providers/pencatatan_provider.dart';
import '../ocr/catat_meteran_screen.dart';

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

  void _showVerificationDialog(BuildContext context, PelangganStatusModel statusModel) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reading = statusModel.reading;
    if (reading == null) return;

    final publicUrl = Supabase.instance.client.storage
        .from('meteran')
        .getPublicUrl(reading.fotoBukti);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SafeArea(
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
                
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verifikasi Bukti Foto',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Customer details
                Text(
                  statusModel.pelanggan.namaLengkap,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  statusModel.pelanggan.alamat,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
                const Divider(height: 24, thickness: 1),
                
                // Reported Reading Value
                Text(
                  'Angka Dilaporkan:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reading.angkaMeteran} m³',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Interactive Image with rounded corners and loading spinner
                Text(
                  'Foto Bukti Meteran (Pinch untuk Zoom):',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.network(
                        publicUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar bukti',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Tutup / Verifikasi button
                PrimaryButton(
                  text: 'Verifikasi Cocok',
                  icon: Icons.check_circle_rounded,
                  height: 54,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
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
                  return const Center(child: Text('Pelanggan tidak ditemukan.', style: TextStyle(fontSize: 13, color: Colors.grey)));
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      customer.namaLengkap,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.3),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      StatusBadge(status: customer.tipePelanggan.name.toUpperCase()),
                                      if (statusModel.hasInputMandiri)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE6F4EA),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: const Text(
                                            'Sudah Input Mandiri',
                                            style: TextStyle(
                                              color: Color(0xFF137333),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F3F4),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: const Text(
                                            'Belum Mencatat',
                                            style: TextStyle(
                                              color: Color(0xFF5F6368),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customer.alamat,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: statusModel.hasInputMandiri
                                    ? PrimaryButton(
                                        text: 'Lihat Bukti Foto',
                                        icon: Icons.image_search_rounded,
                                        width: 170,
                                        height: 44,
                                        color: AppColors.secondary,
                                        onPressed: () {
                                          _showVerificationDialog(context, statusModel);
                                        },
                                      )
                                    : PrimaryButton(
                                        text: 'Catat Meteran',
                                        icon: Icons.camera_alt_rounded,
                                        width: 140,
                                        height: 44,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CatatMeteranScreen(pelanggan: customer),
                                            ),
                                          ).then((_) {
                                            ref.invalidate(pelangganWithStatusProvider);
                                            ref.invalidate(allBillsProvider);
                                          });
                                        },
                                      ),
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
              error: (err, _) => Center(child: Text('Error loading: $err')),
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
