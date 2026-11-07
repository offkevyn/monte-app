// Fails when line coverage of hand-written code drops below a minimum.
//
//   flutter test --coverage
//   dart run tool/check_coverage.dart [minimum, default 70]
//
// Generated files (`*.g.dart`) are left out: they are not code we write.
import 'dart:io';

void main(List<String> args) {
  final minimum = args.isEmpty ? 70.0 : double.parse(args.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exit(2);
  }

  var found = 0;
  var hit = 0;
  var skip = false;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      skip = line.endsWith('.g.dart');
    } else if (!skip && line.startsWith('DA:')) {
      found++;
      if (line.substring(3).split(',')[1] != '0') hit++;
    }
  }

  final percent = found == 0 ? 0.0 : hit * 100 / found;
  final summary =
      'Coverage: ${percent.toStringAsFixed(1)}% ($hit of $found lines, '
      'generated files excluded). Minimum: ${minimum.toStringAsFixed(0)}%.';
  if (percent < minimum) {
    stderr.writeln(summary);
    exit(1);
  }
  stdout.writeln(summary);
}
