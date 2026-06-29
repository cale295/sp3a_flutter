import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/theme/app_colors.dart';
import '../../services/image_processing_service.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        _showErrorSnackBar("Kamera tidak ditemukan");
      }
    } catch (e) {
      debugPrint("Gagal menginisialisasi kamera: $e");
      _showErrorSnackBar("Gagal membuka kamera: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    final size = MediaQuery.of(context).size;

    setState(() {
      _isProcessing = true;
    });

    File? tempFile;
    try {
      // 1. Capture the original full-size photo
      final XFile photo = await _controller!.takePicture();
      final Uint8List originalBytes = await photo.readAsBytes();

      // Bounding box dimensions (must exactly match CameraOverlayPainter)
      final rectWidth = size.width * 0.85;
      final rectHeight = 130.0;
      final rectLeft = (size.width - rectWidth) / 2;
      final rectTop = (size.height - rectHeight) / 2;

      // 2. Crop and enhance the image in memory
      final Uint8List enhancedBytes = await ImageProcessingService.cropAndEnhance(
        imageBytes: originalBytes,
        screenWidth: size.width,
        screenHeight: size.height,
        rectLeft: rectLeft,
        rectTop: rectTop,
        rectWidth: rectWidth,
        rectHeight: rectHeight,
      );

      // 3. Write enhanced bytes to a temp file for ML Kit text recognition
      final tempDir = Directory.systemTemp;
      tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(enhancedBytes);

      // 4. Pass the temp file path to Google ML Kit
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text;
      debugPrint("OCR Raw text on enhanced crop: $text");

      // 5. Clean output text using RegExp(r'\d+') to strip non-digit characters
      final regExp = RegExp(r'\d+');
      final matches = regExp.allMatches(text).map((m) => m.group(0)!).toList();
      final detectedNumber = matches.join('');

      if (mounted) {
        Navigator.pop(context, (detectedNumber, photo));
      }
    } catch (e) {
      debugPrint("OCR / Capture failed: $e");
      _showErrorSnackBar("Gagal memproses gambar: $e");
    } finally {
      // Clean up temporary file
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint("Failed to delete temp file: $e");
        }
      }
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_isInitialized && _controller != null)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: size.width,
                    height: size.width * _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // 2. Custom transparent dark overlay painter
          CustomPaint(
            size: size,
            painter: CameraOverlayPainter(),
          ),

          // 3. Instruction Text Positioned above the target box
          Positioned(
            top: (size.height / 2) - 100,
            left: 20,
            right: 20,
            child: const Text(
              'Posisikan angka meteran di dalam kotak',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // 4. Capture Button Container at the bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Back/Close Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                // Camera Shutter Button
                GestureDetector(
                  onTap: _captureAndProcess,
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black87,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.black87,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Filler spacer for layout balance
                const SizedBox(width: 52),
              ],
            ),
          ),

          // 5. Processing / Loading Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Memproses foto & OCR...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(166)
      ..style = PaintingStyle.fill;

    // 1. Draw the darkened backdrop overlay
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // 2. Define the target box dimensions (placed in the center)
    final rectWidth = size.width * 0.85;
    final rectHeight = 130.0;
    final rectLeft = (size.width - rectWidth) / 2;
    final rectTop = (size.height - rectHeight) / 2;
    
    final targetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight),
      const Radius.circular(16),
    );
    
    final innerPath = Path()..addRRect(targetRect);
    
    // 3. Clip out the target box from the background overlay
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(path, paint);

    // 4. Draw the border line around the target box
    final borderPaint = Paint()
      ..color = AppColors.primary // Water Blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(targetRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
