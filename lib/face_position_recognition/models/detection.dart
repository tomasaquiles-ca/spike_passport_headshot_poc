import 'package:google_ml_kit/google_ml_kit.dart';

class Detection {
  const Detection({
    required this.face,
    this.smiling = false,
    this.leftEyeClosed = false,
    this.rightEyeClosed = false,
    this.angled = false,
    this.earsMissing = false,
  });

  final Face? face;
  final bool smiling;
  final bool leftEyeClosed;
  final bool rightEyeClosed;
  final bool angled;
  final bool earsMissing;

  bool get wellPositioned =>
      !smiling && !leftEyeClosed && !rightEyeClosed && !angled && !earsMissing;

  // (Possibly multiline) text explaining all the reasons why the face is not well positioned
  // it can be because the face is angled, left eye is closed, right eye is closed, person is smiling, or because the ears are missing
  String get reasons => [
        if (smiling) 'Person is smiling',
        if (leftEyeClosed) 'Left eye is closed',
        if (rightEyeClosed) 'Right eye is closed',
        if (angled) 'Face is angled',
        if (earsMissing) 'Ears are missing',
      ].join('\n');

  Detection copyWith({
    Face? face,
    bool? smiling,
    bool? leftEyeClosed,
    bool? rightEyeClosed,
    bool? angled,
    bool? earsMissing,
  }) =>
      Detection(
        face: face ?? this.face,
        smiling: smiling ?? this.smiling,
        leftEyeClosed: leftEyeClosed ?? this.leftEyeClosed,
        rightEyeClosed: rightEyeClosed ?? this.rightEyeClosed,
        angled: angled ?? this.angled,
        earsMissing: earsMissing ?? this.earsMissing,
      );
}
