import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'package:spike_pictures_poc/document_information_extraction/document_information_extraction.dart';

part 'document_information_extraction_state.dart';

class DocumentInformationExtractionCubit
    extends Cubit<DocumentInformationExtractionState> {
  DocumentInformationExtractionCubit({
    this.stopOnSuccess = true,
    this.filterOn = 5,
    this.clearCacheInterval = const Duration(seconds: 10),
  }) : super(DocumentInformationExtractionInitial()) {
    _clearCache();
  }

  final Duration clearCacheInterval;
  final bool stopOnSuccess;
  final int filterOn;
  List<List<String>> accumulatedResults = [];

  Timer? _clearCacheTimer;

  void _clearCache() {
    _clearCacheTimer?.cancel();
    _clearCacheTimer = Timer(clearCacheInterval, () {
      accumulatedResults.clear();
      _clearCache();
    });
  }

  @override
  Future<void> close() {
    _clearCacheTimer?.cancel();
    return super.close();
  }

  void _processAll() {
    final filteredResults = MRZHelper.processMRZTextResults(accumulatedResults);
    final mrzResult = MRZParser.tryParse(filteredResults);

    log('Accumulated results: $accumulatedResults');
    log('Filtered results: $filteredResults');

    if (mrzResult == null) {
      emit(DocumentInformationExtractionError(
        'Unable to parse text',
        filteredResults.toString(),
      ));
      return;
    }

    emit(DocumentInformationExtractionLoaded(mrzResult));
  }

  Future<void> extractInformation(
    CameraImage image,
    CameraDescription description,
  ) async {
    if (state is DocumentInformationExtractionLoaded && stopOnSuccess) {
      return;
    }

    if (TextIdentifier.isScanning) {
      return;
    }

    if (accumulatedResults.length >= filterOn) {
      _processAll();
    }

    emit(DocumentInformationExtractionLoading());
    List<String>? parseableText;
    try {
      final recognizedText = await TextIdentifier.scanImage(image, description)
          .timeout(const Duration(seconds: 1));
      if (state is DocumentInformationExtractionLoaded && stopOnSuccess) {
        return;
      }

      final fullText = recognizedText.text;

      String trimmedText = fullText.replaceAll(' ', '');
      final allText = trimmedText.split('\n');

      List<String> ableToScanText = [];
      for (var e in allText) {
        final testLine = MRZHelper.testTextLine(e);
        if (testLine.isNotEmpty) {
          ableToScanText.add(testLine);
        }
      }

      parseableText = MRZHelper.getFinalListToParse(ableToScanText);
      final parsed = MRZParser.tryParse(parseableText);

      if (parsed?.givenNames.nullIfEmpty == null ||
          parsed?.surnames.nullIfEmpty == null) {
        emit(DocumentInformationExtractionError(
          'Unable to parse text',
          parseableText.toString(),
        ));
        return;
      }

      accumulatedResults.add(parseableText!);

      if (accumulatedResults.length >= filterOn) {
        _processAll();
      }
    } catch (e) {
      if (state is DocumentInformationExtractionLoaded && stopOnSuccess) {
        return;
      }

      emit(DocumentInformationExtractionError(
        e.toString(),
        parseableText.toString(),
      ));
    }
  }

  void reset() {
    accumulatedResults.clear();
    emit(DocumentInformationExtractionInitial());
  }
}
