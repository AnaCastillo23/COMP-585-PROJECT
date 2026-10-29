import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Largest image we store inside a Firestore document.
const int maxStoredImageBytes = 150 * 1024;

/// Shrinks an image to a JPEG under [maxStoredImageBytes].
/// Returns null if the file isn't a readable image or can't be made small enough.
Uint8List? compressImage(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;

  final image = img.bakeOrientation(decoded);
  var maxSide = 640;
  var quality = 80;

  while (true) {
    final resized = image.width >= image.height
        ? img.copyResize(image, width: image.width > maxSide ? maxSide : image.width)
        : img.copyResize(image, height: image.height > maxSide ? maxSide : image.height);

    final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    if (out.lengthInBytes <= maxStoredImageBytes) return out;

    if (quality > 50) {
      quality -= 10;
    } else if (maxSide > 240) {
      maxSide -= 100;
    } else {
      return null;
    }
  }
}