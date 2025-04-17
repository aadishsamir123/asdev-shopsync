// ignore_for_file: invalid_runtime_check_with_js_interop_types

import 'dart:js_interop';
import 'package:web/web.dart';
import 'dart:convert';

void exportForWeb(String csvData, String listName) {
  final bytes = utf8.encode(csvData);
  final blob =
      Blob([bytes] as JSArray<BlobPart>, BlobPropertyBag(type: 'text/csv'));
  final url = URL.createObjectURL(blob);

  // ignore: unused_local_variable
  final anchor = document.createElement('a') as HTMLAnchorElement
    ..href = url
    ..setAttribute('download', '$listName.csv')
    ..click();

  URL.revokeObjectURL(url);
}
