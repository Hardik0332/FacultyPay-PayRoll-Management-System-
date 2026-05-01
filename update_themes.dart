import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('ZoomPageTransitionsBuilder') || content.contains('NoAnimationPageTransitionsBuilder')) {
      if (!content.contains('package:animations/animations.dart')) {
        content = "import 'package:animations/animations.dart';\n" + content;
      }
      content = content.replaceAll('ZoomPageTransitionsBuilder()', 'SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled)');
      content = content.replaceAll('CupertinoPageTransitionsBuilder()', 'SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.scaled)');
      
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
