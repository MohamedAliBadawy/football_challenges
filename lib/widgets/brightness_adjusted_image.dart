import 'dart:typed_data';

import 'package:flutter/material.dart';

class BrightnessAdjustedImage extends StatelessWidget {
  final Uint8List image;
  final double brightness;

  BrightnessAdjustedImage({required this.image, this.brightness = 0.5});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        1,
        0,
        0,
        0,
        brightness * 255,
        0,
        1,
        0,
        0,
        brightness * 255,
        0,
        0,
        1,
        0,
        brightness * 255,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Image.memory(image),
    );
  }
}
