import 'package:mrz_parser/mrz_parser.dart';

class MRZHelper {
  static List<String>? getFinalListToParse(List<String> ableToScanTextList) {
    if (ableToScanTextList.length < 2) {
      // minimum length of any MRZ format is 2 lines
      return null;
    }
    int lineLength = ableToScanTextList.first.length;
    for (var e in ableToScanTextList) {
      if (e.length != lineLength) {
        return null;
      }
      // to make sure that all lines are the same in length
    }
    List<String> firstLineChars = ableToScanTextList.first.split('');
    List<String> supportedDocTypes = ['A', 'C', 'P', 'V', 'I'];

    String fChar = firstLineChars[0];
    String sChar = firstLineChars[1];

    if (supportedDocTypes.contains(fChar)) {
      if (sChar == '<' || RegExp(r'^[A-Z]$').hasMatch(sChar)) {
        return ableToScanTextList;
      }
    }
    return null;
  }

  static String testTextLine(String text) {
    String res = text.replaceAll(' ', '');
    List<String> list = res.split('');

    // to check if the text belongs to any MRZ format or not
    if (list.length != 44 && list.length != 30 && list.length != 36) {
      return '';
    }

    for (int i = 0; i < list.length; i++) {
      if (RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(list[i])) {
        list[i] = list[i].toUpperCase();
        // to ensure that every letter is uppercase
      }
      if (double.tryParse(list[i]) == null &&
          !(RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(list[i]))) {
        list[i] = '<';
        // sometimes < sign not recognized well
      }
    }
    String result = list.join('');
    return result;
  }

  static List<String> processMRZTextResults(List<List<String>> mrzTextResults) {
    final falsePositiveFiltered = _filterFalsePositives(mrzTextResults);
    final validated = _validateMRZResults(falsePositiveFiltered);
    return _selectFinalMRZResult(validated);
  }

  static List<List<String>> _filterFalsePositives(List<List<String>> results) {
    List<List<String>> filteredResults = [];

    for (int i = 0; i < results.length; i++) {
      List<String> result = results[i];
      List<String> filteredResult = List.from(result);

      for (int j = 0; j < result.length; j++) {
        String line = result[j];
        for (int k = 0; k < line.length; k++) {
          String character = line[k];

          if (character == 'K') {
            // Check previous and next characters in the same line
            if (k > 0 &&
                k < line.length - 1 &&
                line[k - 1] == '<' &&
                line[k + 1] == '<') {
              // Replace 'Ks' with '<'
              filteredResult[j] = filteredResult[j].replaceRange(k, k + 1, '<');
            }

            // Check neighboring characters in previous and next detections, same line
            if (i > 0 && i < results.length - 1) {
              String prevLine = results[i - 1][j];
              String nextLine = results[i + 1][j];

              if (k < prevLine.length &&
                  k < nextLine.length &&
                  prevLine[k] == '<' &&
                  nextLine[k] == '<') {
                // Replace 'Ks' with '<'
                filteredResult[j] =
                    filteredResult[j].replaceRange(k, k + 1, '<');
              }
            }
          }
        }
      }

      filteredResults.add(filteredResult);
    }

    return filteredResults;
  }

  static List<List<String>> _validateMRZResults(List<List<String>> results) {
    List<List<String>> validResults = [];
    for (List<String> result in results) {
      // Use the MRZ parsing library to validate the MRZ format
      try {
        final mrzDocument = MRZParser.tryParse(result);
        if (mrzDocument != null) {
          validResults.add(result);
        }
      } catch (e) {
        // Ignore the exception
      }
    }
    return validResults;
  }

  static List<String> _selectFinalMRZResult(List<List<String>> results) {
    List<String> finalResult = [];

    // Iterate through each line of the MRZ text results
    for (int i = 0; i < results[0].length; i++) {
      String line = results[0][i];
      bool isSameAcrossAllResults = true;

      // Check if the line is the same across all MRZ text results
      for (int j = 1; j < results.length; j++) {
        if (results[j][i] != line) {
          isSameAcrossAllResults = false;
          break;
        }
      }

      // If the line is the same across all results, add it to the final result
      if (isSameAcrossAllResults) {
        finalResult.add(line);
      } else {
        // If the line differs across results, calculate the average line
        finalResult.add(_calculateAverageLine(results, i));
      }
    }

    return finalResult;
  }

  static String _calculateAverageLine(List<List<String>> results, int index) {
    String averageLine = '';
    int totalCount = results.length;

    // Iterate over each MRZ text result to calculate the average line at the given index
    for (int i = 0; i < totalCount; i++) {
      String line = results[i][index];
      int lineLength = line.length;

      // Accumulate the characters at the given index across all MRZ text results
      for (int j = 0; j < lineLength; j++) {
        if (averageLine.length <= j) {
          // If the average line is shorter than the current line, append the character
          averageLine += line[j];
        } else if (averageLine[j] != line[j]) {
          // If the character differs, replace it with the most common character in this index accross all results
          Map<String, int> charCounts = {};
          for (int k = 0; k < totalCount; k++) {
            String char = results[k][index][j];
            if (charCounts.containsKey(char)) {
              charCounts[char] = charCounts[char]! + 1;
            } else {
              charCounts[char] = 1;
            }
          }

          String mostCommonChar = '';
          int mostCommonCharCount = 0;
          charCounts.forEach((char, count) {
            if (count > mostCommonCharCount) {
              mostCommonChar = char;
              mostCommonCharCount = count;
            }
          });

          averageLine = averageLine.replaceRange(j, j + 1, mostCommonChar);
        }
      }
    }

    return averageLine;
  }
}
