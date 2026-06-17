import 'dart:io';

void main() {
  final dir = Directory('lib/screen');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content
      .replaceAll('const TextStyle(', 'TextStyle(')
      .replaceAll('const IconThemeData(', 'IconThemeData(')
      .replaceAll('const BoxDecoration(', 'BoxDecoration(')
      .replaceAll('const SnackBar(', 'SnackBar(')
      .replaceAll('const InputDecoration(', 'InputDecoration(');
    
    if (content != newContent) {
      file.writeAsStringSync(newContent);
      print('Fixed consts in \${file.path}');
    }
  }
}
