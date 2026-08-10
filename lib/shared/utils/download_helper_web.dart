// lib/shared/utils/download_helper_web.dart

import 'dart:convert';
import 'dart:html' as html;

void downloadCsvTemplate(String content, String fileName) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
