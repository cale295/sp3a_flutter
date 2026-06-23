import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/input_field.dart';
import '../../models/user_model.dart';

class CatatMeteranScreen extends ConsumerStatefulWidget {
  final UserModel pelanggan;

  const CatatMeteranScreen({super.key, required this.pelanggan});

  @override
  ConsumerState<CatatMeteranScreen> createState() => _CatatMeteranScreenState();
}

class _CatatMeteranScreenState extends ConsumerState<CatatMeteranScreen> {
  // Camera variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraSupported = false;

  // OCR/Image variables
  File? _selectedImageFile; // For Mobile
  Uint8List? _selectedImageBytes; // For Web
  // ignore: unused_field — referenced by camera/pick callbacks; _submitReading is deprecated
  String? _selectedImageName;
  final _meterValueController = TextEditingController();
  
  bool _isProcessing = false;
  // ignore: prefer_final_fields — mutated indirectly through setState in camera callbacks
  bool _isUploading = false;
  
  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _checkPlatformAndInit();
  }

  void _checkPlatformAndInit() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _isCameraSupported = true;
      });
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _meterValueController.dispose();
    super.dispose();
  }

  // Mobile: Trigger image capture and run ML Kit OCR
  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File file = File(photo.path);
      
      setState(() {
        _selectedImageFile = file;
        _selectedImageName = 'meter_${widget.pelanggan.id}_${_currentMonth}_$_currentYear.jpg';
      });

      final inputImage = InputImage.fromFile(file);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      String text = recognizedText.text;
      debugPrint("OCR Raw text: $text");
      
      final regExp = RegExp(r'\b\d{4,6}\b');
      final match = regExp.firstMatch(text);
      
      if (match != null) {
        _meterValueController.text = match.group(0) ?? '';
      } else {
        final generalNumbers = RegExp(r'\d+');
        final allMatches = generalNumbers.allMatches(text);
        if (allMatches.isNotEmpty) {
          _meterValueController.text = allMatches.first.group(0) ?? '';
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan OCR berhasil! Harap verifikasi hasil angka.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal scan: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Web/Fallback: Select image file and let user input manually
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        setState(() {
          _selectedImageName = 'meter_${widget.pelanggan.id}_${_currentMonth}_${_currentYear}_$timestamp.${file.extension ?? 'jpg'}';
          
          if (kIsWeb) {
            _selectedImageBytes = file.bytes;
          } else {
            _selectedImageFile = File(file.path!);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DEPRECATED: Self-meter input by customers is no longer supported.
  // Meter readings are now exclusively recorded by Petugas officers via the
  // numeric input dialog in PetugasDashboard. This screen is kept for
  // reference only and is NOT reachable from any live navigation route.
  // ──────────────────────────────────────────────────────────────────────────
  void _submitReading() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pencatatan mandiri tidak lagi didukung. Hubungi Petugas SP3A Anda.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Catat Meteran Air', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(31)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pencatatan air untuk ${widget.pelanggan.namaLengkap} - Periode: Bulan $_currentMonth / $_currentYear',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Camera UI or Uploader Fallback
              if (_isCameraSupported && _isCameraInitialized && _selectedImageFile == null)
                Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CameraPreview(_cameraController!),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withAlpha(102),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 240,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.transparent,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Posisikan Angka Meteran di Dalam Kotak',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Ambil Foto & Scan OCR',
                      icon: Icons.camera_rounded,
                      isLoading: _isProcessing,
                      onPressed: _captureAndScan,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Unggah Gambar dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: _pickImage,
                    ),
                  ],
                )
              else ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: isDark ? null : AppColors.lightShadow,
                  ),
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_selectedImageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (_selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  const Text('Belum ada foto terpilih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  const SizedBox(height: 4),
                                  const Text('Unggah foto meteran air Anda untuk memvalidasi', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                                  const SizedBox(height: 18),
                                  PrimaryButton(
                                    text: 'Pilih Foto Meteran',
                                    icon: Icons.photo_library_rounded,
                                    width: 180,
                                    height: 38,
                                    onPressed: _pickImage,
                                  ),
                                ],
                              ),
                            )),
                ),
                if (_selectedImageFile != null || _selectedImageBytes != null) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Ulangi Ambil / Pilih Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      });
                      if (_isCameraSupported) {
                        _initializeCamera();
                      }
                    },
                  ),
                ],
              ],
              const SizedBox(height: 28),

              // Reading Form Field
              InputField(
                label: 'Angka Meteran Air saat ini (m³)',
                hint: 'Masukkan hasil pencatatan meteran',
                controller: _meterValueController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.speed_rounded,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Kirim Pencatatan',
                isLoading: _isUploading,
                onPressed: _submitReading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
