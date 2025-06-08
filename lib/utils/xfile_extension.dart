import 'dart:convert';
import 'package:image_picker/image_picker.dart';

extension XfileExtension on XFile {
  Future<String> getBase64Image() async {
    String fileExt = path.split('.').last.toLowerCase();
    String mimeType = '';

    switch (fileExt) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break; // Added break to prevent fall-through
      case 'png':
        mimeType = 'image/png';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      case 'bmp':
        mimeType = 'image/bmp';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      default:
        mimeType = 'image/jpeg'; // Fallback for unknown types
    }

    // Read the file as bytes synchronously
    List<int> imageBytes = await readAsBytes();

    // Convert bytes to Base64
    final String base64 = base64Encode(imageBytes);

    return 'data:$mimeType;base64,$base64';
  }
}
