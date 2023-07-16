import 'package:flutter/material.dart';
import 'package:spike_pictures_poc/face_position_recognition/models/detection.dart';

class FacePainter extends CustomPainter {
  const FacePainter(
    this.imageSize,
    this.detection,
  );

  final Size imageSize;
  final Detection detection;

  @override
  void paint(Canvas canvas, Size size) {
    final face = detection.face;
    if (face == null) return;

    Paint paint;

    if (!detection.wellPositioned) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;
    } else {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.green;
    }

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    final scaledRect = _scaleRect(
      rect: face.boundingBox,
      imageSize: imageSize,
      widgetSize: size,
      scaleX: scaleX,
      scaleY: scaleY,
    );

    canvas.drawRRect(
      scaledRect,
      paint,
    );

    if (!detection.wellPositioned) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: detection.reasons,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          scaledRect.right.toDouble(),
          scaledRect.bottom.toDouble(),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.detection != detection;
  }
}

RRect _scaleRect({
  required Rect rect,
  required Size imageSize,
  required Size widgetSize,
  double? scaleX,
  double? scaleY,
}) {
  return RRect.fromLTRBR(
    (widgetSize.width - rect.left.toDouble() * scaleX!),
    rect.top.toDouble() * scaleY!,
    widgetSize.width - rect.right.toDouble() * scaleX,
    rect.bottom.toDouble() * scaleY,
    const Radius.circular(10),
  );
}
