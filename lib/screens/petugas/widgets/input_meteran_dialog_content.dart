import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import '../../ocr/camera_scan_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/pencatatan_meteran_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tagihan_provider.dart';
import '../../../providers/pencatatan_provider.dart';

class InputMeteranDialogContent extends ConsumerStatefulWidget {
  final UserModel customer;

  const InputMeteranDialogContent({super.key, required this.customer});

  @override
  ConsumerState<InputMeteranDialogContent> createState() =>
      _InputMeteranDialogContentState();
}

class _InputMeteranDialogContentState
    extends ConsumerState<InputMeteranDialogContent> {
  final _angkaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  XFile? _capturedImage;
  String? _ocrStatusText;
  bool _isOcrLoading = false;

  // Previous reading states
  PencatatanMeteranModel? _previousReading;
  bool _isLoadingPrevious = true;

  // Track if validation has failed due to previous reading check
  bool _validationFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchPreviousReading();
  }

  @override
  void dispose() {
    _angkaController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreviousReading() async {
    final now = DateTime.now();
    try {
      final prev = await ref.read(meteranServiceProvider).getPreviousReading(
            pelangganId: widget.customer.id,
            currentMonth: now.month,
            currentYear: now.year,
          );
      if (mounted) {
        setState(() {
          _previousReading = prev;
          _isLoadingPrevious = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching previous reading: $e");
      if (mounted) {
        setState(() {
          _isLoadingPrevious = false;
        });
      }
    }
  }

  Future<void> _openCameraScan() async {
    try {
      final result = await Navigator.push<(String, XFile)>(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraScanScreen(),
        ),
      );

      if (result != null) {
        final (detectedNumber, photo) = result;
        setState(() {
          _capturedImage = photo;
          _validationFailed = false; // Reset warning border
          if (detectedNumber.isNotEmpty) {
            _angkaController.text = detectedNumber;
            _ocrStatusText = "Angka terdeteksi, silakan periksa kembali";
          } else {
            _ocrStatusText = "Gagal mendeteksi angka, masukkan secara manual";
          }
        });
        _formKey.currentState?.validate();
      }
    } catch (e) {
      debugPrint("Error navigating to camera scan: $e");
      setState(() {
        _ocrStatusText = "Gagal memproses gambar: $e";
      });
    }
  }

  void _showPreviousReadingLowerDialog(int prevValue) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 12),
              Text(
                'Peringatan Validasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Angka meteran lebih rendah dari bulan lalu ($prevValue m³). Silakan periksa kembali atau revisi hasil scan.',
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Periksa Kembali',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitData() async {
    // Force set validation flag to false first
    setState(() {
      _validationFailed = false;
    });

    if (!_formKey.currentState!.validate()) return;

    final currentInputStr = _angkaController.text.trim();
    final currentInput = int.tryParse(currentInputStr) ?? 0;

    // PREVIOUS MONTH VALIDATION
    final prevValue = _previousReading?.angkaMeteran ?? 0;
    if (currentInput < prevValue) {
      setState(() {
        _validationFailed = true;
      });
      // Force trigger validation so TextFormField highlights in red
      _formKey.currentState!.validate();

      // Show the required clear error dialog
      _showPreviousReadingLowerDialog(prevValue);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final authState = ref.read(authProvider);
    final petugasId = authState.user?.id ?? 'unknown';
    final scaffoldMsg = ScaffoldMessenger.of(context);

    try {
      await ref.read(meteranServiceProvider).petugasInputMeter(
            pelangganId: widget.customer.id,
            dicatatOlehId: petugasId,
            periodeBulan: now.month,
            periodeTahun: now.year,
            angkaMeter: currentInput,
            imageFile: _capturedImage!,
          );

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
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
                  'Meteran ${widget.customer.namaLengkap} berhasil dicatat dan tagihan dibuat.',
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final bulanLabel = DateFormat('MMMM yyyy', 'id_ID').format(now);

    final canSubmit = !_isSubmitting &&
        !_isOcrLoading &&
        !_isLoadingPrevious &&
        _angkaController.text.trim().isNotEmpty &&
        _capturedImage != null;

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
              key: _formKey,
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
                                widget.customer.namaLengkap,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.customer.alamat,
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
                  const SizedBox(height: 12),

                  // Previous Month Info Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLoadingPrevious
                          ? (isDark ? Colors.white.withAlpha(5) : Colors.grey[100])
                          : (_validationFailed
                              ? AppColors.error.withAlpha(15)
                              : (isDark ? Colors.white.withAlpha(10) : AppColors.primary.withAlpha(10))),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _validationFailed
                            ? AppColors.error.withAlpha(50)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: _validationFailed ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _validationFailed ? Icons.error_outline_rounded : Icons.history_toggle_off_rounded,
                          color: _validationFailed ? AppColors.error : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingPrevious
                              ? Row(
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Mengambil data bulan lalu...',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Angka Meteran Bulan Lalu',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: _validationFailed
                                            ? AppColors.error
                                            : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _previousReading != null
                                          ? '${_previousReading!.angkaMeteran} m³  (Periode: ${_previousReading!.periodeBulan}/${_previousReading!.periodeTahun})'
                                          : 'Belum ada catatan meteran sebelumnya (0 m³)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _validationFailed
                                            ? AppColors.error
                                            : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Camera/Photo Section
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
                  if (_capturedImage == null)
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
                      onPressed: _openCameraScan,
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
                              File(_capturedImage!.path),
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
                                setState(() {
                                  _capturedImage = null;
                                  _ocrStatusText = null;
                                  _isOcrLoading = false;
                                  _angkaController.clear();
                                  _validationFailed = false;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                  // OCR Status text below the image
                  if (_isOcrLoading || _ocrStatusText != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (_isOcrLoading) ...[
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
                            _ocrStatusText ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _isOcrLoading
                                  ? (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary)
                                  : AppColors.primary,
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
                    controller: _angkaController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      setState(() {
                        _validationFailed = false;
                      });
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: _validationFailed
                          ? AppColors.error
                          : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
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
                        color: _validationFailed ? AppColors.error : AppColors.primary,
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
                        borderSide: BorderSide(
                          color: _validationFailed ? AppColors.error : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      enabledBorder: _validationFailed
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                            )
                          : null,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 2),
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

                      // Check previous month reading validation inside the validator
                      final prevVal = _previousReading?.angkaMeteran ?? 0;
                      if (parsed < prevVal) {
                        return 'Lebih rendah dari bulan lalu ($prevVal m³)';
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
                        backgroundColor: _validationFailed ? AppColors.error : AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withAlpha(80),
                        disabledForegroundColor: Colors.grey,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSubmitting
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
                        _isSubmitting ? 'Menyimpan & Mengunggah...' : 'Simpan & Hitung Tagihan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      onPressed: canSubmit ? _submitData : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
