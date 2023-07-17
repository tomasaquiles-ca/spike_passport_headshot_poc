import 'package:flutter_test/flutter_test.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'package:spike_pictures_poc/document_information_extraction/document_information_extraction.dart';

void main() {
  test('Parses', () {
    final lines = [
      'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
      '5326147613USA6112309M2508223269990094<477004'
    ];

    final parsed = MRZParser.parse(lines);
    expect(parsed, isNotNull);
  });

  test('filters the result', () {
    final mrzTexts = [
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<K<<<<<<<<K<<<',
        '5326147613USA6112309M2508223269990094<477004',
      ],
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004',
      ],
      [
        'P<USANEILSON<<DANEKCHRISTIAN<<K<<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004',
      ],
      [
        'P<USANEILSON<KDANE<CHRISTIAN<<<<<<<<K<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004',
      ],
    ];

    const expectedFiltered = [
      'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
      '5326147613USA6112309M2508223269990094<477004',
    ];

    final filteredResults = MRZHelper.processMRZTextResults(mrzTexts);
    expect(filteredResults, expectedFiltered);
  });

  test('filters the result', () {
    final accumulated = [
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004'
      ],
      [
        'P<USANEILSON<<DANE<CHRISTIANK<<<<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004'
      ],
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004'
      ],
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
        '53261476130SA6112309M2508223269990094<477004'
      ],
      [
        'P<USANEILSON<<DANE<CHRISTIAN<<<K<<<<<<<<<<<<',
        '5326147613USA6112309M2508223269990094<477004'
      ],
    ];

    const expectedFiltered = [
      'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
      '5326147613USA6112309M2508223269990094<477004',
    ];

    final filteredResults = MRZHelper.processMRZTextResults(accumulated);
    expect(filteredResults, expectedFiltered);
  });
}
