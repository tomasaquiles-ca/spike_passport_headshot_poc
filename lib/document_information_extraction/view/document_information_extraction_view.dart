import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spike_pictures_poc/document_information_extraction/document_information_extraction.dart';
import 'package:spike_pictures_poc/main.dart';

class DocumentInformationExtraction extends StatelessWidget {
  const DocumentInformationExtraction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocumentInformationExtractionCubit(),
      child: const DocumentInformationExtractionView(),
    );
  }
}

class DocumentInformationExtractionView extends StatefulWidget {
  const DocumentInformationExtractionView({super.key});

  @override
  State<DocumentInformationExtractionView> createState() =>
      _DocumentInformationExtractionViewState();
}

class _DocumentInformationExtractionViewState
    extends State<DocumentInformationExtractionView>
    with WidgetsBindingObserver {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraController(cameras.firstWhere(
        (element) => element.lensDirection == CameraLensDirection.back,
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
    final state = context.select(
      (DocumentInformationExtractionCubit cubit) => cubit.state,
    );

    if (state is DocumentInformationExtractionLoaded) {
      final flag = state.result.countryCode.toUpperCase().replaceAllMapped(
            RegExp(r'[A-Z]'),
            (match) =>
                String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
          );

      return Scaffold(
        persistentFooterButtons: [
          ElevatedButton(
            onPressed: () {
              context.read<DocumentInformationExtractionCubit>().reset();
            },
            child: const Text('Scan again'),
          ),
        ],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Names: ${state.result.givenNames}'),
              Text('Surnames: ${state.result.surnames}'),
              Text('Sex: ${state.result.sex.name}'),
              Text('Country code: ${state.result.countryCode} $flag'),
              Text('ID: ${state.result.documentNumber}'),
              Text('Date of birth: ${state.result.birthDate}'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: (controller != null && controller!.value.isInitialized)
          ? CameraPreview(controller!)
          : const Center(child: CircularProgressIndicator()),
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

    final cubit = context.read<DocumentInformationExtractionCubit>();
    controller?.startImageStream((image) {
      cubit.extractInformation(image, description);
    });

    setState(() {});
  }
}
