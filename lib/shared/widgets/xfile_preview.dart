import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class XFilePreview extends StatelessWidget {
  const XFilePreview({
    super.key,
    required this.imageFile,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  final XFile imageFile;
  final BoxFit fit;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ??
        const ColoredBox(
          color: Colors.black12,
          child: Center(
            child: Icon(Icons.broken_image_outlined),
          ),
        );

    if (kIsWeb) {
      return Image.network(
        imageFile.path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.file(
      File(imageFile.path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
