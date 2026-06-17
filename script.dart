import 'dart:io';

void main() {
  final dir = Directory('lib/screen');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Background color
    if (content.contains('backgroundColor: const Color(0xFFF5F0E8)')) {
      content = content.replaceAll('backgroundColor: const Color(0xFFF5F0E8)', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
      modified = true;
    }
    if (content.contains('backgroundColor: Color(0xFFF5F0E8)')) {
      content = content.replaceAll('backgroundColor: Color(0xFFF5F0E8)', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
      modified = true;
    }

    // Text color
    if (content.contains('color: const Color(0xFF0D4A4A)')) {
      content = content.replaceAll('color: const Color(0xFF0D4A4A)', 'color: Theme.of(context).colorScheme.onSurface');
      modified = true;
    }
    if (content.contains('color: Color(0xFF0D4A4A)')) {
      content = content.replaceAll('color: Color(0xFF0D4A4A)', 'color: Theme.of(context).colorScheme.onSurface');
      modified = true;
    }

    // Colors.white in BoxDecoration -> cardColor
    // This is trickier since Colors.white is used in many places.
    // Let's replace `color: Colors.white,` if it looks like it's in a container/box decoration, but it's safer to just let the script do it. 
    // Actually, I should just stick to replacing specific known hardcoded ones.
    
    if (modified) {
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
