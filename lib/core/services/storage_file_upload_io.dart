import 'dart:io';

Future<bool> fileExists(String path) {
  return File(path).exists();
}
