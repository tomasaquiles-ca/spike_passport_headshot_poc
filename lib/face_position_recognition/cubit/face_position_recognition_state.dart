part of 'face_position_recognition_cubit.dart';

@immutable
abstract class FacePositionRecognitionState extends Equatable {
  const FacePositionRecognitionState();

  @override
  List<Object> get props => [];
}

class FacePositionRecognitionInitial extends FacePositionRecognitionState {
  const FacePositionRecognitionInitial();
}

class FacePositionRecognitionNotFound extends FacePositionRecognitionState {
  const FacePositionRecognitionNotFound();
}

class FacePositionRecognitionUnsupported extends FacePositionRecognitionState {
  const FacePositionRecognitionUnsupported();
}

class FacePositionRecognitionFound extends FacePositionRecognitionState {
  const FacePositionRecognitionFound(this.detection);

  final Detection detection;

  @override
  List<Object> get props => [detection];
}
