import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:spike_pictures_poc/face_position_recognition/face_position_recognition.dart';

class FaceIdentifier {
  static Future<Detection?> scanImage({
    required CameraImage image,
    required CameraDescription camera,
  }) async {
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

    return _detectFace(inputImage);
  }

  static Future<Detection?> _detectFace(InputImage inputImage) async {
    final options = FaceDetectorOptions(enableClassification: true);
    final faceDetector = FaceDetector(options: options);

    try {
      final faces = await faceDetector.processImage(inputImage);

      final detectedFace = _extractFace(faces);
      return detectedFace;
    } catch (error) {
      debugPrint(error.toString());
      return null;
    }
  }

  static _extractFace(List<Face> faces) {
    bool angled = false;
    bool earsMissing = false;
    bool smiling = false;
    bool leftEyeClosed = false;
    bool rightEyeClosed = false;

    Face? detectedFace;

    for (Face face in faces) {
      detectedFace = face;

      // Head is rotated to the right rotY degrees
      if (face.headEulerAngleY! > 5 || face.headEulerAngleY! < -5) {
        angled = true;
      }

      // Head is tilted sideways rotZ degrees
      if (face.headEulerAngleZ! > 5 || face.headEulerAngleZ! < -5) {
        angled = true;
      }

      // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final FaceLandmark? rightEar = face.landmarks[FaceLandmarkType.rightEar];
      if (leftEar != null && rightEar != null) {
        if (leftEar.position.y < 0 ||
            leftEar.position.x < 0 ||
            rightEar.position.y < 0 ||
            rightEar.position.x < 0) {
          earsMissing = true;
        }
      }

      if (face.leftEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.5) {
          leftEyeClosed = true;
        }
      }

      if (face.rightEyeOpenProbability != null) {
        if (face.rightEyeOpenProbability! < 0.5) {
          rightEyeClosed = true;
        }
      }

      if (face.smilingProbability != null) {
        if (face.smilingProbability! > 0.5) {
          smiling = true;
        }
      }
    }

    return Detection(
      face: detectedFace,
      smiling: smiling,
      leftEyeClosed: leftEyeClosed,
      rightEyeClosed: rightEyeClosed,
      angled: angled,
      earsMissing: earsMissing,
    );
  }
}
