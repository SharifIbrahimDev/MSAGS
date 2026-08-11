// lib/shared/utils/file_reader_helper_native.dart

import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';

Future<String> readPlatformFileAsString(PlatformFile file) async {
  if (file.path != null) {
    final ioFile = io.File(file.path!);
    return await ioFile.readAsString();
  }
  return '';
}
