import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:meta/meta.dart';
import 'package:spike_pictures_poc/face_position_recognition/face_position_recognition.dart';

part 'face_position_recognition_state.dart';

class FacePositionRecognitionCubit extends Cubit<FacePositionRecognitionState> {
  FacePositionRecognitionCubit()
      : super(const FacePositionRecognitionInitial());

  final options = FaceDetectorOptions(
    enableClassification: true,
    enableContours: true,
  );
  late final faceDetector = FaceDetector(options: options);

  bool isDetecting = false;

  Future<void> detectFaces(
    CameraImage cameraImage,
    CameraDescription camera,
  ) async {
    if (isDetecting) {
      return;
    }

    isDetecting = true;
    Detection? detection;

    try {
      detection = await FaceIdentifier.scanImage(
        image: cameraImage,
        camera: camera,
      );
    } catch (e) {
      emit(const FacePositionRecognitionUnsupported());
      isDetecting = false;
      return;
    }

    isDetecting = false;

    if (detection == null) {
      emit(const FacePositionRecognitionNotFound());
      return;
    }

    emit(FacePositionRecognitionFound(detection));
  }

  void safeEmit(FacePositionRecognitionState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
