import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  /// Crops the image byte array in-memory and applies grayscale and binarization.
  /// Runs on a background isolate via compute.
  static Future<Uint8List> cropAndEnhance({
    required Uint8List imageBytes,
    required double screenWidth,
    required double screenHeight,
    required double rectLeft,
    required double rectTop,
    required double rectWidth,
    required double rectHeight,
  }) async {
    return compute(_cropAndEnhanceIsolate, {
      'imageBytes': imageBytes,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'rectLeft': rectLeft,
      'rectTop': rectTop,
      'rectWidth': rectWidth,
      'rectHeight': rectHeight,
    });
  }

  static Uint8List _cropAndEnhanceIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final screenWidth = params['screenWidth'] as double;
    final screenHeight = params['screenHeight'] as double;
    final rectLeft = params['rectLeft'] as double;
    final rectTop = params['rectTop'] as double;
    final rectWidth = params['rectWidth'] as double;
    final rectHeight = params['rectHeight'] as double;

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw const OSError("Failed to decode image bytes into img.Image");
    }

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    double scale;
    double offsetX = 0.0;
    double offsetY = 0.0;

    final screenRatio = screenWidth / screenHeight;
    final imageRatio = imageWidth / imageHeight;

    if (imageRatio > screenRatio) {
      // Image is wider than screen: height scaled, width cropped on sides
      scale = imageHeight / screenHeight;
      offsetX = (imageWidth - (screenWidth * scale)) / 2;
    } else {
      // Image is taller than screen: width scaled, height cropped on top/bottom
      scale = imageWidth / screenWidth;
      offsetY = (imageHeight - (screenHeight * scale)) / 2;
    }

    int cropX = (rectLeft * scale + offsetX).round();
    int cropY = (rectTop * scale + offsetY).round();
    int cropW = (rectWidth * scale).round();
    int cropH = (rectHeight * scale).round();

    // Clamp coordinates to stay within image bounds
    cropX = cropX.clamp(0, image.width - 1);
    cropY = cropY.clamp(0, image.height - 1);
    cropW = cropW.clamp(1, image.width - cropX);
    cropH = cropH.clamp(1, image.height - cropY);

    // 1. Crop image in memory
    final cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 2. Grayscale
    final grayscale = img.grayscale(cropped);

    // 3. Binarize / Thresholding (Make digits pop: luminance < 128 is black, >= 128 is white)
    for (final pixel in grayscale) {
      final luminance = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
      if (luminance < 128) {
        pixel.setRgb(0, 0, 0); // Black
      } else {
        pixel.setRgb(255, 255, 255); // White
      }
    }

    // 4. Encode as JPEG bytes in memory
    return Uint8List.fromList(img.encodeJpg(grayscale, quality: 90));
  }
}
