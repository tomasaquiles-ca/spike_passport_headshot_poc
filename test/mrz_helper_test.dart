import 'package:flutter_test/flutter_test.dart';
import 'package:mrz_parser/mrz_parser.dart';

void main() {
  test('Parses', () {
    final lines = [
      'P<USANEILSON<<DANE<CHRISTIAN<<<<<<<<<<<<<<<<',
      '5326147613USA6112309M2508223269990094<477004'
    ];

    final parsed = MRZParser.parse(lines);
    expect(parsed, isNotNull);
  });
}
