import 'package:flutter/services.dart';

class ImageToWebp {
  // macos only

  static final platform = MethodChannel('com.ikhwan.image_converter');

  static Future<Uint8List?> convert(
    Uint8List imageBytes, {
    double quality = 0.8,
  }) async {
    try {
      final result = await platform.invokeMethod<Uint8List>('convertToWebP', {
        'image': imageBytes,
        'quality': quality,
      });
      return result;
    } catch (e) {
      print("Error converting to WebP: $e");
      return null;
    }
  }
}
