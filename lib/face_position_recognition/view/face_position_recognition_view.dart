import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spike_pictures_poc/face_position_recognition/face_position_recognition.dart';
import 'package:spike_pictures_poc/main.dart';

class FacePositionRecognition extends StatelessWidget {
  const FacePositionRecognition({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FacePositionRecognitionCubit(),
      child: const FacePositionRecognitionView(),
    );
  }
}

class FacePositionRecognitionView extends StatefulWidget {
  const FacePositionRecognitionView({super.key});

  @override
  State<FacePositionRecognitionView> createState() =>
      _FacePositionRecognitionViewState();
}

class _FacePositionRecognitionViewState
    extends State<FacePositionRecognitionView> with WidgetsBindingObserver {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraController(cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.front,
      ));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = controller!;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cameraPreview() => CameraPreview(controller!);

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: BlocBuilder<FacePositionRecognitionCubit,
          FacePositionRecognitionState>(
        builder: (context, state) {
          if (controller != null && controller!.value.isInitialized) {
            if (state is FacePositionRecognitionFound) {
              log('FacePositionRecognitionFound');

              return Center(
                child: Transform.scale(
                  scale: 1.0,
                  child: AspectRatio(
                    aspectRatio: size.aspectRatio,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          width: size.width,
                          height: size.width * controller!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              cameraPreview(),
                              SizedBox(
                                width: controller!.value.previewSize!.width,
                                height: controller!.value.previewSize!.height,
                                child: CustomPaint(
                                  painter: FacePainter(
                                    Size(
                                      controller!.value.previewSize!.height,
                                      controller!.value.previewSize!.width,
                                    ),
                                    state.detection,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return cameraPreview();
          }

          return const Text(
            'No Camera Detected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  Future<void> _initializeCameraController(
    CameraDescription description,
  ) async {
    controller = CameraController(
      description,
      ResolutionPreset.max,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await controller?.initialize();

    if (!mounted) {
      return;
    }

    final cubit = context.read<FacePositionRecognitionCubit>();
    controller?.startImageStream((image) {
      cubit.detectFaces(image, controller!.description);
    });

    setState(() {});
  }
}
