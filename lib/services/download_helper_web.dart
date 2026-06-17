import 'dart:typed_data';
import 'dart:html' as html;

void downloadBytes(Uint8List bytes, String filename) {
  final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
