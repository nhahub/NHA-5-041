/// Turns TheMealDB's free-text `strInstructions` into clean numbered steps.
class InstructionParser {
  const InstructionParser._();

  /// Lines shorter than this (and not ending a sentence) are merged into the
  /// previous step.
  static const _tinyLength = 25;

  static final _stepHeader = RegExp(
    r'^\s*step\s*\d+\s*[:.\-)]?\s*$',
    caseSensitive: false,
  );
  static final _stepPrefix = RegExp(
    r'^\s*(step\s*)?\d+\s*[:.\-)]\s*',
    caseSensitive: false,
  );
  static final _loneNumber = RegExp(r'^\s*\d+\s*[.)]?\s*$');

  static List<String> parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .where((l) => !_stepHeader.hasMatch(l) && !_loneNumber.hasMatch(l))
        .map((l) => l.replaceFirst(_stepPrefix, '').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final steps = <String>[];
    for (final line in lines) {
      final endsSentence = RegExp(r'[.!?]["\)]?$').hasMatch(line);
      final tiny = line.length < _tinyLength && !endsSentence;
      if (steps.isNotEmpty &&
          (tiny ||
              steps.last.length < _tinyLength && !_endsSentence(steps.last))) {
        steps[steps.length - 1] = '${steps.last} $line';
      } else {
        steps.add(line);
      }
    }
    return steps;
  }

  static bool _endsSentence(String s) => RegExp(r'[.!?]["\)]?$').hasMatch(s);
}
