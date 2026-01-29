import 'dart:io';

void main(List<String> args) {
  final root = Directory.current;
  final libDir = Directory(_join(root.path, 'lib'));
  final screensDir = Directory(_join(libDir.path, 'screens'));

  if (!libDir.existsSync()) {
    stderr.writeln('Expected `lib/` at: ${libDir.path}');
    exitCode = 2;
    return;
  }
  if (!screensDir.existsSync()) {
    stderr.writeln('Expected `lib/screens/` at: ${screensDir.path}');
    exitCode = 2;
    return;
  }

  final allDartFiles = libDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.dart'))
      .toList();

  final screenFiles = screensDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final contentsByPath = <String, String>{};
  for (final file in allDartFiles) {
    try {
      contentsByPath[file.path] = file.readAsStringSync();
    } catch (e) {
      stderr.writeln('Failed to read: ${file.path} ($e)');
    }
  }

  final orphanScreens = <String>[];

  for (final screenFile in screenFiles) {
    final screenPath = screenFile.path;
    final screenContent = contentsByPath[screenPath] ?? '';
    final screenFileName = _basename(screenPath);

    final classNames = _extractClassNames(screenContent)
        .where((name) => name.isNotEmpty && !name.startsWith('_'))
        .toSet();

    var referenced = false;

    for (final entry in contentsByPath.entries) {
      if (entry.key == screenPath) continue;
      final content = entry.value;

      if (content.contains(screenFileName)) {
        referenced = true;
        break;
      }

      for (final className in classNames) {
        if (_containsWord(content, className)) {
          referenced = true;
          break;
        }
      }

      if (referenced) break;
    }

    if (!referenced) {
      orphanScreens.add(_relativePath(root.path, screenPath));
    }
  }

  if (orphanScreens.isEmpty) {
    stdout.writeln('No orphan screens found.');
    return;
  }

  stdout.writeln('Orphan screens (${orphanScreens.length}):');
  for (final p in orphanScreens) {
    stdout.writeln('- $p');
  }
}

List<String> _extractClassNames(String source) {
  final re = RegExp(r'^\s*class\s+([A-Za-z_]\w*)\b', multiLine: true);
  return re.allMatches(source).map((m) => m.group(1) ?? '').toList();
}

bool _containsWord(String haystack, String needle) {
  final re = RegExp('\\b${RegExp.escape(needle)}\\b');
  return re.hasMatch(haystack);
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  return idx == -1 ? normalized : normalized.substring(idx + 1);
}

String _join(String a, String b) {
  if (a.endsWith('\\') || a.endsWith('/')) return '$a$b';
  final sep = Platform.pathSeparator;
  return '$a$sep$b';
}

String _relativePath(String rootPath, String fullPath) {
  final root = rootPath.replaceAll('\\', '/');
  final full = fullPath.replaceAll('\\', '/');
  if (full.startsWith(root)) {
    var rel = full.substring(root.length);
    while (rel.startsWith('/')) {
      rel = rel.substring(1);
    }
    return rel;
  }
  return fullPath;
}
