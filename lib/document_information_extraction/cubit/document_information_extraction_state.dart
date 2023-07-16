part of 'document_information_extraction_cubit.dart';

abstract class DocumentInformationExtractionState extends Equatable {
  const DocumentInformationExtractionState();

  @override
  List<Object> get props => [];
}

class DocumentInformationExtractionInitial
    extends DocumentInformationExtractionState {}

class DocumentInformationExtractionLoading
    extends DocumentInformationExtractionState {}

class DocumentInformationExtractionLoaded
    extends DocumentInformationExtractionState {
  final MRZResult result;

  const DocumentInformationExtractionLoaded(this.result);

  @override
  List<Object> get props => [result];
}

class DocumentInformationExtractionError
    extends DocumentInformationExtractionState {
  const DocumentInformationExtractionError(this.message, this.inputText);

  final String message;
  final String inputText;

  @override
  List<Object> get props => [message, inputText];
}
