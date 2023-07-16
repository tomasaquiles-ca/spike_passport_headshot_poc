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
  }) : super(DocumentInformationExtractionInitial());

  final bool stopOnSuccess;

  Future<void> extractInformation(
    CameraImage image,
    CameraDescription description,
  ) async {
    if (state is DocumentInformationExtractionLoading) {
      return;
    }

    if (state is DocumentInformationExtractionLoaded && stopOnSuccess) {
      return;
    }

    emit(DocumentInformationExtractionLoading());

    final recognizedText = await TextIdentifier.scanImage(image, description);
    final fullText = recognizedText.text;

    if (fullText.isEmpty) {
      emit(const DocumentInformationExtractionError('No text recognized', ''));
      return;
    }

    String trimmedText = fullText.replaceAll(' ', '');
    final allText = trimmedText.split('\n');

    List<String> ableToScanText = [];
    for (var e in allText) {
      if (MRZHelper.testTextLine(e).isNotEmpty) {
        ableToScanText.add(MRZHelper.testTextLine(e));
      }
    }
    List<String>? parseableText = MRZHelper.getFinalListToParse(ableToScanText);

    try {
      final parsed = MRZParser.parse(parseableText);
      emit(DocumentInformationExtractionLoaded(parsed));
    } catch (e) {
      emit(DocumentInformationExtractionError(
        e.toString(),
        parseableText.toString(),
      ));
    }
  }

  void reset() {
    emit(DocumentInformationExtractionInitial());
  }
}
