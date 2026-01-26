import 'dart:io';

import 'package:falcon_gui/utils/logger.dart';
import 'package:falcon_gui/utils/paths.dart';
import 'package:file_picker/file_picker.dart';

class FalconFilePicker {
  static const String graphFileExtension = 'yaml';

  static Future<File?> pickGraphFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: [graphFileExtension],
        initialDirectory: defaultGraphsDirectory.path,
        dialogTitle: 'Select a Falcon Graph File',
        type: FileType.custom,
        lockParentWindow: true,
        // ignore: avoid_redundant_argument_values
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          return File(filePath);
        }
      }
    } catch (e, s) {
      logError('Error picking graph file: $e', s);
    }
    return null;
  }

  static Future<File?> createNewGraphFile() async {
    try {
      final result = await FilePicker.platform.saveFile(
        allowedExtensions: [graphFileExtension],
        initialDirectory: defaultGraphsDirectory.path,
        dialogTitle: 'Create a New Falcon Graph File',
        type: FileType.custom,
        lockParentWindow: true,
        fileName: 'my_graph.$graphFileExtension',
      );

      if (result != null) {
        return File(result)..createSync(recursive: true);
      }
    } catch (e, s) {
      logError('Error creating new graph file: $e', s);
    }

    return null;
  }
}
