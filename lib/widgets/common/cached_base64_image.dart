import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CachedBase64Image extends StatefulWidget {
  final String base64;
  final double maxSize;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const CachedBase64Image({
    super.key,
    required this.base64,
    this.maxSize = 100,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<CachedBase64Image> createState() => _CachedBase64ImageState();
}

class _CachedBase64ImageState extends State<CachedBase64Image> {
  Uint8List? _imageBytes;

  @override
  void didUpdateWidget(covariant CachedBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64 != widget.base64) {
      _decodeBase64();
    }
  }

  @override
  void initState() {
    super.initState();
    _decodeBase64();
  }

  void _decodeBase64() {
    if (!mounted) return;
    setState(() {
      _imageBytes = base64Decode(widget.base64);
    });
  }

  void _showFullScreenImage() {
    if (_imageBytes == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Center(
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(top: 20, right: 20),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.clear,
                        size: 30,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return SizedBox(
        width: widget.maxSize,
        height: widget.maxSize,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.maxSize,
          maxHeight: widget.maxSize,
        ),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          image: DecorationImage(
            image: MemoryImage(_imageBytes!),
            fit: widget.fit,
          ),
        ),
      ),
    );
  }
}
