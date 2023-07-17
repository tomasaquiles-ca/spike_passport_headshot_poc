import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextIdentifier {
  static bool isScanning = false;

  static Future<RecognizedText> scanImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (isScanning) {
      throw Exception('Already scanning');
    }

    isScanning = true;
    try {
      final WriteBuffer allBytes = WriteBuffer();

      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      return _detectText(inputImage);
    } catch (e) {
      rethrow;
    } finally {
      isScanning = false;
    }
  }

  static Future<RecognizedText> _detectText(InputImage inputImage) async {
    return _recognizer.processImage(inputImage);
  }

  static final _recognizer = TextRecognizer();
}
