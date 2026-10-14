import 'dart:typed_data';

import '../../../core/models/homework_helper_result.dart';

class PickedHomeworkImage {
  const PickedHomeworkImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

sealed class HomeworkState {
  const HomeworkState();
}

/// The upload/capture step — also shown after a failed analysis (the
/// photo and the error message stick around so the student can just
/// retry, mirroring the web app's combined idle/error phase). Holds raw
/// bytes rather than a file path/`XFile` so the preview (`Image.memory`)
/// and the upload work identically on web and mobile — a path-based
/// `Image.file` approach doesn't compile on Flutter web at all.
final class HomeworkPicking extends HomeworkState {
  const HomeworkPicking({this.image, this.errorMessage});

  final PickedHomeworkImage? image;
  final String? errorMessage;
}

final class HomeworkAnalyzing extends HomeworkState {
  const HomeworkAnalyzing();
}

final class HomeworkResultReady extends HomeworkState {
  const HomeworkResultReady(this.result, {this.image});
  final HomeworkHelperResult result;

  /// The analyzed photo, shown above the guidance.
  final PickedHomeworkImage? image;
}
