import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadCsvWeb(String csvContent, String filename) {
  // Blob encodes JS strings as UTF-8 without a lossy base64/binary-string step.
  final blob = web.Blob(
    <JSAny>[csvContent.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final link = web.HTMLAnchorElement()..download = filename;
  final url = web.URL.createObjectURL(blob);
  try {
    link
      ..href = url
      ..style.display = 'none';
    web.document.body!.appendChild(link);
    link.click();
  } finally {
    link.remove();
    // Allow the browser to start consuming the download before releasing it.
    Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  }
}
