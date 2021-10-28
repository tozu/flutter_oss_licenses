import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_pubspec_licenses/dart_pubspec_licenses.dart' as oss;
import 'package:path/path.dart' as path;

main(List<String> args) async {
  final pubCacheDirPath = oss.guessPubCacheDir();
  try {
    if (oss.flutterDir == null) {
      print('FLUTTER_ROOT is not set.');
      return 1;
    } else if (pubCacheDirPath == null) {
      print('Could not determine PUB_CACHE directory.');
      return 2;
    } else if (args.length == 1 && (args[0] == '--help' || args[0] == '-h')) {
      print('Usage: generate.dart [OUTPUT_FILE_PATH [PROJECT_ROOT]]');
      return 3;
    }

    final projectRoot = args.length >= 2 ? args[1] : await findProjectRoot();
    final outputFilePath = args.isNotEmpty ? args[0] : path.join(projectRoot, 'lib', 'oss_licenses.dart');
    final licenses = await oss.generateLicenseInfo(
      pubspecLockPath: path.join(projectRoot, 'pubspec.lock'),
    );

    final dartCode = '''// cSpell:disable
// ignore_for_file: prefer_single_quotes

/// This code was generated by flutter_oss_licenses
/// https://pub.dev/packages/flutter_oss_licenses
final ossLicenses = <String, dynamic>''' +
        const JsonEncoder.withIndent("  ").convert(licenses) +
        ';';

    await File(outputFilePath).writeAsString(dartCode);
    return 0;
  } catch (e, s) {
    print('$e: $s');
    return 4;
  }
}

Future<String> findProjectRoot({Directory? from}) async {
  from = from ?? Directory.current;
  if (await File(path.join(from.path, 'pubspec.yaml')).exists()) {
    return from.path;
  }
  return findProjectRoot(from: from.parent);
}
