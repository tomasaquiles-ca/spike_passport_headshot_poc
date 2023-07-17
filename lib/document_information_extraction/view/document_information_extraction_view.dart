import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mrz_parser/mrz_parser.dart';
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
    return BlocConsumer<DocumentInformationExtractionCubit,
        DocumentInformationExtractionState>(
      builder: (context, state) {
        if (state is DocumentInformationExtractionLoaded) {
          return Scaffold(
            persistentFooterButtons: [
              ElevatedButton(
                onPressed: () async {
                  context.read<DocumentInformationExtractionCubit>().reset();
                  await startImageSteam();
                },
                child: const Text('Scan again'),
              ),
            ],
            body: Center(
              child: Text(
                stringifyMrz(state.result),
              ),
            ),
          );
        }

        return Scaffold(
          body: (controller != null && controller!.value.isInitialized)
              ? CameraPreview(controller!)
              : const Center(child: CircularProgressIndicator()),
        );
      },
      listener: (context, state) async {
        if (state is DocumentInformationExtractionLoaded &&
            (controller?.value.isStreamingImages ?? false)) {
          await controller?.stopImageStream();
        }
      },
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

    await startImageSteam();

    setState(() {});
  }

  Future<void> startImageSteam() async {
    final cubit = context.read<DocumentInformationExtractionCubit>();
    bool processing = false;
    await controller?.startImageStream((image) async {
      if (processing) return;
      processing = true;
      await cubit.extractInformation(image, controller!.description);
      processing = false;
    });
  }
}

String stringifyMrz(MRZResult result) {
  final nationalityFlag = result.nationalityCountryCode.nullIfEmpty
      ?.substring(0, min(2, result.nationalityCountryCode.length))
      .toUpperCase()
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
      );

  final flag = result.countryCode
      .substring(0, min(2, result.nationalityCountryCode.length))
      .toUpperCase()
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
      );

  final dateFormat = DateFormat('dd/MM/yyyy');

  return '''
Names: ${result.givenNames.capitalize().orElse('N/A')}
Surnames: ${result.surnames.capitalize().orElse('N/A')}
Birthdate: ${dateFormat.format(result.birthDate)}
Nationality Country Code: ${result.nationalityCountryCode} $nationalityFlag
Country Code: ${result.countryCode} $flag
Document Number: ${result.documentNumber.orElse('N/A')}
Personal Number: ${result.personalNumber.orElse('N/A')}
Personal Number 2: ${result.personalNumber2.orElse('N/A')}
Expiry Date 2: ${dateFormat.format(result.expiryDate)}
Sex: ${result.sex.name.capitalize()}
          ''';
}

extension OrElse on String? {
  String? orElse(String defaultValue) {
    if (this == null) return defaultValue;
    return (this?.isEmpty ?? true) ? defaultValue : this;
  }
}

extension Capitalize on String {
  String? capitalize() {
    if (nullIfEmpty == null) return null;
    final spaceSplit = trim().split(' ');
    return spaceSplit
        .map((e) => e.isEmpty
            ? null
            : e[0].toUpperCase() + e.substring(1).toLowerCase())
        .join(' ');
  }
}

extension NullIfEmpty on String {
  String? get nullIfEmpty => trim().isEmpty ? null : this;
}
