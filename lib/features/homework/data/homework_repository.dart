import 'dart:typed_data';

import '../../../core/models/homework_helper_result.dart';
import '../../../core/network/api_client.dart';

/// The only place in the app that calls `/api/homework-helper` — a photo
/// upload through [ApiClient.postMultipart], so it carries the student's
/// session (the route is authenticated and budgeted, see
/// apps/web/lib/aiGate.ts). The server uses the student's own class.
///
/// Takes raw bytes rather than a `dart:io File`/path — the latter
/// doesn't compile on Flutter web at all.
class HomeworkRepository {
  HomeworkRepository(this._api);

  final ApiClient _api;

  Future<HomeworkHelperResult> analyzeImage({
    required Uint8List imageBytes,
    required String filename,
    required int grade,
    required String lang,
  }) async {
    final Map<String, dynamic> data = await _api.postMultipart(
      '/api/homework-helper',
      fields: {'lang': lang},
      files: [(bytes: imageBytes, filename: filename)],
    );
    return HomeworkHelperResult.fromJson(data);
  }
}
