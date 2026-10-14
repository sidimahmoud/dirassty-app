import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thrown when the Next.js API returns a non-2xx response or an error body.
/// [message] is student-facing (the AI routes return French text, see
/// apps/web/lib/aiGate.ts); [code] is stable (`ai_limit_tokens`,
/// `ai_rate_limited`, `ai_bad_image`, …) for screens that react to it.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.status});

  final String message;
  final String? code;
  final int? status;

  /// The student used up today's AI budget (or is rate-limited).
  bool get isLimit => status == 429;

  @override
  String toString() => message;
}

/// The only place in the app that calls the Next.js API routes (AI
/// generation/correction — anything that must stay server-side). Screens
/// and providers go through a feature's repository, which goes through
/// this, never `http`/`dio` directly. Every call carries the signed-in
/// session's access token: the AI routes refuse anonymous calls and
/// charge the student's AI budget server-side.
class ApiClient {
  ApiClient({http.Client? client, String? Function()? accessToken})
      : _client = client ?? http.Client(),
        _accessToken = accessToken ?? (() => null);

  final http.Client _client;
  final String? Function() _accessToken;

  static const Duration _timeout = Duration(seconds: 70);

  Map<String, String> _auth() {
    final String? token = _accessToken();
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {'Content-Type': 'application/json', ..._auth()},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(response);
  }

  /// Multipart POST — [files] are sent under the field name `images`.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<({Uint8List bytes, String filename})> files,
  }) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$path'))
          ..headers.addAll(_auth())
          ..fields.addAll(fields);
    for (final f in files) {
      request.files.add(http.MultipartFile.fromBytes('images', f.bytes,
          filename: f.filename));
    }
    final http.StreamedResponse streamed =
        await _client.send(request).timeout(_timeout);
    return _decode(await http.Response.fromStream(streamed));
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Erreur serveur', status: response.statusCode);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded['error'] as String? ?? 'Erreur serveur',
        code: decoded['code'] as String?,
        status: response.statusCode,
      );
    }
    return decoded;
  }
}
