import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import 'gemini_prompt.dart';

/// One HTTP exchange, shaped so a test can replace the network entirely.
class AiHttpRequest {
  const AiHttpRequest({
    required this.uri,
    required this.headers,
    required this.body,
    required this.timeout,
  });

  final Uri uri;
  final Map<String, String> headers;
  final String body;
  final Duration timeout;
}

class AiHttpResponse {
  const AiHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef AiHttpTransport = Future<AiHttpResponse> Function(
  AiHttpRequest request,
);

enum GeminiErrorKind {
  missingKey,
  timeout,
  network,
  unauthorized,
  rateLimited,
  badRequest,
  server,
  invalidResponse,
}

/// A model failure with copy that is safe to show in the UI.
class GeminiException implements Exception {
  const GeminiException(this.kind, this.message, {this.statusCode});

  final GeminiErrorKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class GeminiConfig {
  const GeminiConfig({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    this.endpoint = 'https://generativelanguage.googleapis.com/v1beta',
    this.timeout = const Duration(seconds: 25),
    this.maxOutputTokens = 900,
    this.systemPrompt = defaultGeminiSystemPrompt,
  });

  /// Reads the current `.env` values. Call this when a request is made, not at
  /// app start, so an edited file is picked up on the next run.
  factory GeminiConfig.fromEnvironment(String apiKey) => GeminiConfig(
    apiKey: apiKey,
    model: AppEnv.geminiModel,
    endpoint: AppEnv.geminiApiUrl,
    timeout: AppEnv.aiTimeout,
    maxOutputTokens: AppEnv.aiMaxOutputTokens,
    systemPrompt: AppEnv.geminiSystemPrompt,
  );

  final String apiKey;
  final String model;
  final String endpoint;
  final Duration timeout;
  final int maxOutputTokens;
  final String systemPrompt;

  Uri get generateContentUri {
    final base = endpoint.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/models/$model:generateContent');
  }
}

class GeminiObservation {
  const GeminiObservation({
    required this.title,
    required this.detail,
    required this.tone,
    required this.tag,
  });

  final String title;
  final String detail;
  final String tone;
  final String tag;
}

class GeminiSuggestion {
  const GeminiSuggestion({required this.title, required this.detail});

  final String title;
  final String detail;
}

class GeminiAnalysis {
  const GeminiAnalysis({
    required this.headline,
    required this.summary,
    required this.observations,
    required this.suggestions,
    required this.conversationStarters,
  });

  final String headline;
  final String summary;
  final List<GeminiObservation> observations;
  final List<GeminiSuggestion> suggestions;
  final List<String> conversationStarters;
}

/// A dependency-free Gemini client.
///
/// The analyzer sends one structured brief with a strict JSON response schema,
/// so the UI never has to parse free-form prose. Failures are typed and short;
/// [AiAnalyzerService] turns them into a local-report fallback.
class GeminiAnalyzer {
  GeminiAnalyzer({required this.config, AiHttpTransport? transport})
    : _transport = transport ?? _defaultTransport;

  final GeminiConfig config;
  final AiHttpTransport _transport;

  Duration get timeout => config.timeout;

  Future<GeminiAnalysis> analyze({
    required String brief,
    AppStrings strings = AppStrings.english,
  }) async {
    if (config.apiKey.trim().isEmpty) {
      throw GeminiException(GeminiErrorKind.missingKey, strings.geminiNoKey);
    }

    final request = AiHttpRequest(
      uri: config.generateContentUri,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'x-goog-api-key': config.apiKey,
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': config.systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': brief},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topP': 0.9,
          'maxOutputTokens': config.maxOutputTokens,
          'responseMimeType': 'application/json',
          'responseSchema': _responseSchema,
        },
      }),
      timeout: timeout,
    );

    AiHttpResponse response;
    try {
      response = await _transport(request);
    } on GeminiException {
      rethrow;
    } on TimeoutException {
      throw GeminiException(GeminiErrorKind.timeout, strings.geminiTookTooLong);
    } on SocketException {
      throw GeminiException(GeminiErrorKind.network, strings.geminiUnreachable);
    } on TlsException {
      throw GeminiException(
        GeminiErrorKind.network,
        strings.geminiNoSecureConnection,
      );
    } on HttpException {
      throw GeminiException(
        GeminiErrorKind.network,
        strings.geminiRequestIncomplete,
      );
    }

    if (response.statusCode != 200) {
      throw _statusError(response, strings);
    }

    return _parse(response.body, strings);
  }

  GeminiException _statusError(AiHttpResponse response, AppStrings strings) {
    final detail = _apiDetail(response.body);
    final suffix = detail.isEmpty ? '' : ' $detail';

    if (response.statusCode == 401 || response.statusCode == 403) {
      return GeminiException(
        GeminiErrorKind.unauthorized,
        strings.geminiKeyRejected(suffix),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 429) {
      return GeminiException(
        GeminiErrorKind.rateLimited,
        strings.geminiBusy(suffix),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 400 || response.statusCode == 404) {
      return GeminiException(
        GeminiErrorKind.badRequest,
        strings.geminiRequestRejected(suffix),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 500) {
      return GeminiException(
        GeminiErrorKind.server,
        strings.geminiUnavailable(suffix),
        statusCode: response.statusCode,
      );
    }
    return GeminiException(
      GeminiErrorKind.server,
      strings.geminiUnexpectedStatus(response.statusCode, suffix),
      statusCode: response.statusCode,
    );
  }

  /// Gemini's error payload is `{"error": {"message": "..."}}`. Only a short
  /// message is surfaced, with credential-shaped fragments redacted and the
  /// raw body never shown to a parent.
  String _apiDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return '';
      final error = decoded['error'];
      if (error is! Map) return '';
      final message = error['message'];
      if (message is! String) return '';
      final cleaned = message
          .replaceAllMapped(
            RegExp(
              r'\b(key|token|authorization)\b\s*[=:]\s*\S+',
              caseSensitive: false,
            ),
            (match) => '${match[1]}=[redacted]',
          )
          .replaceAll(RegExp(r'AIza[0-9A-Za-z\-_]{10,}'), '[redacted]')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return cleaned.length <= 160 ? cleaned : '${cleaned.substring(0, 157)}…';
    } catch (_) {
      return '';
    }
  }

  GeminiAnalysis _parse(String body, AppStrings strings) {
    final Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      envelope = decoded;
    } on FormatException {
      throw GeminiException(
        GeminiErrorKind.invalidResponse,
        strings.geminiUnreadable,
      );
    }

    final promptFeedback = envelope['promptFeedback'];
    if (promptFeedback is Map) {
      final blocked = promptFeedback['blockReason'];
      if (blocked is String && blocked.isNotEmpty) {
        throw GeminiException(
          GeminiErrorKind.invalidResponse,
          strings.geminiDeclined,
        );
      }
    }

    final candidates = envelope['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw GeminiException(
        GeminiErrorKind.invalidResponse,
        strings.geminiNoAnalysis,
      );
    }

    final parts = _partsText(candidates.first);
    if (parts.isEmpty) {
      throw GeminiException(
        GeminiErrorKind.invalidResponse,
        strings.geminiEmptyAnalysis,
      );
    }

    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(_stripFences(parts));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      payload = decoded;
    } on FormatException {
      throw GeminiException(
        GeminiErrorKind.invalidResponse,
        strings.geminiUnexpectedShape,
      );
    }

    final headline = _text(payload['headline']);
    final summary = _text(payload['summary']);
    final observations = _observations(payload['observations'], strings);
    final suggestions = _suggestions(payload['suggestions']);
    final starters = _starters(payload['conversationStarters']);

    if (headline == null ||
        summary == null ||
        observations.length < 2 ||
        suggestions.isEmpty) {
      throw GeminiException(
        GeminiErrorKind.invalidResponse,
        strings.geminiIncompleteAnalysis,
      );
    }

    return GeminiAnalysis(
      headline: headline,
      summary: summary,
      observations: observations.take(5).toList(),
      suggestions: suggestions.take(3).toList(),
      conversationStarters: starters.take(3).toList(),
    );
  }

  String _partsText(Object? candidate) {
    if (candidate is! Map) return '';
    final content = candidate['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map) continue;
      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(text);
      }
    }
    return buffer.toString().trim();
  }

  String _stripFences(String value) {
    var text = value.trim();
    if (!text.startsWith('```')) return text;
    text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    text = text.replaceFirst(RegExp(r'\s*```$'), '');
    return text.trim();
  }

  String? _text(Object? value) {
    if (value is! String) return null;
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  List<GeminiObservation> _observations(Object? value, AppStrings strings) {
    if (value is! List) return const [];
    final result = <GeminiObservation>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final title = _text(entry['title']);
      final detail = _text(entry['detail']);
      if (title == null || detail == null) continue;
      final tone = _text(entry['tone'])?.toLowerCase();
      result.add(
        GeminiObservation(
          title: title,
          detail: detail,
          tone: tone == 'positive' || tone == 'attention' ? tone! : 'neutral',
          tag: _text(entry['tag']) ?? strings.tagPattern,
        ),
      );
    }
    return result;
  }

  List<GeminiSuggestion> _suggestions(Object? value) {
    if (value is! List) return const [];
    final result = <GeminiSuggestion>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final title = _text(entry['title']);
      final detail = _text(entry['detail']);
      if (title == null || detail == null) continue;
      result.add(GeminiSuggestion(title: title, detail: detail));
    }
    return result;
  }

  List<String> _starters(Object? value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is String && entry.trim().isNotEmpty)
          entry.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];
  }

  static Future<AiHttpResponse> _defaultTransport(AiHttpRequest request) async {
    final client = HttpClient()..connectionTimeout = request.timeout;
    try {
      final httpRequest = await client
          .postUrl(request.uri)
          .timeout(request.timeout);
      request.headers.forEach(httpRequest.headers.set);
      httpRequest.add(utf8.encode(request.body));

      final response = await httpRequest.close().timeout(request.timeout);
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(request.timeout);
      return AiHttpResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }

  static const _responseSchema = {
    'type': 'OBJECT',
    'properties': {
      'headline': {'type': 'STRING'},
      'summary': {'type': 'STRING'},
      'observations': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'detail': {'type': 'STRING'},
            'tone': {
              'type': 'STRING',
              'enum': ['positive', 'attention', 'neutral'],
            },
            'tag': {'type': 'STRING'},
          },
          'required': ['title', 'detail', 'tone', 'tag'],
        },
      },
      'suggestions': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'detail': {'type': 'STRING'},
          },
          'required': ['title', 'detail'],
        },
      },
      'conversationStarters': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
    },
    'required': [
      'headline',
      'summary',
      'observations',
      'suggestions',
      'conversationStarters',
    ],
  };
}
