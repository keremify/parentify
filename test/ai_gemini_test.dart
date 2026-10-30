import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/config/env.dart';
import 'package:parentify/data/demo_data.dart';
import 'package:parentify/services/ai_analyzer_service.dart';
import 'package:parentify/services/gemini_analyzer.dart';

const _validKey = 'AIzaSyDemoKeyForTestsOnly1234567890';

Map<String, Object?> _payload({
  String headline = 'A steady week with a late Saturday',
  String summary = 'Most days look balanced. Saturday ran longer than usual.',
}) => {
  'headline': headline,
  'summary': summary,
  'observations': [
    {
      'title': 'Saturday ran long',
      'detail': 'A single long session carried most of the extra time.',
      'tone': 'attention',
      'tag': 'Today',
    },
    {
      'title': 'Evenings wind down',
      'detail': 'The last hour before bed stayed quiet.',
      'tone': 'positive',
      'tag': 'Bedtime',
    },
    {
      'title': 'Games lead the week',
      'detail': 'Games took the largest share of app time.',
      'tone': 'neutral',
      'tag': 'Apps',
    },
  ],
  'suggestions': [
    {'title': 'Try a ten-minute warning', 'detail': 'Agree on a heads-up.'},
    {'title': 'Keep bedtime shared', 'detail': 'Charge devices together.'},
    {'title': 'Ask about the game', 'detail': 'Show curiosity first.'},
  ],
  'conversationStarters': [
    'What made Saturday feel different?',
    'How did the last hour before bed feel?',
    'What would make next week feel balanced?',
  ],
};

String _geminiEnvelope(Object payload) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': payload is String ? payload : jsonEncode(payload)},
        ],
      },
    },
  ],
});

GeminiAnalyzer _analyzer(
  Future<AiHttpResponse> Function(AiHttpRequest) transport, {
  String model = 'gemini-test',
}) => GeminiAnalyzer(
  config: GeminiConfig(
    apiKey: _validKey,
    model: model,
    systemPrompt: 'SYSTEM PROMPT',
    timeout: const Duration(milliseconds: 50),
  ),
  transport: transport,
);

AiAnalyzerService _service(
  Future<AiHttpResponse> Function(AiHttpRequest) transport, {
  String? apiKey = _validKey,
}) => AiAnalyzerService(
  apiKey: apiKey,
  localLatency: Duration.zero,
  clientBuilder: (_) => _analyzer(transport),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AppEnv.reset);

  group('Env file parsing', () {
    test('reads keys, comments, quotes and escaped newlines', () {
      final values = parseEnvFile('''
# a comment
; another comment
GEMINI_MODEL=gemini-2.5-flash
export DEMO_PARENT_PASSWORD="pass=word"
QUOTED='single value'
MULTILINE=one\\ntwo
EMPTY=
NO_EQUALS
''');

      expect(values['GEMINI_MODEL'], 'gemini-2.5-flash');
      expect(values['DEMO_PARENT_PASSWORD'], 'pass=word');
      expect(values['QUOTED'], 'single value');
      expect(values['MULTILINE'], 'one\ntwo');
      expect(values['EMPTY'], '');
      expect(values['NO_EQUALS'], isNull);
      expect(values.entries, isNot(contains('a comment')));
    });

    test('reads the bundled .env and prompt assets', () async {
      await AppEnv.load(bundle: rootBundle);

      expect(AppEnv.isLoaded, isTrue);
      expect(AppEnv.geminiModel, 'gemini-2.5-flash');
      expect(AppEnv.demoParentEmail, 'parent@parentify.dev');
      expect(AppEnv.demoChildPin, '2026');
      expect(AppEnv.geminiSystemPrompt, contains('family screen-time analyst'));
      expect(AppEnv.geminiSystemPrompt, contains('OUTPUT CONTRACT'));
    });

    test('falls back when the configured model id is unsafe', () {
      AppEnv.use(parseEnvFile('GEMINI_MODEL=../../v1beta/evil'));

      expect(AppEnv.geminiModel, 'gemini-2.5-flash');
    });
  });

  group('Gemini request', () {
    test(
      'sends the system prompt, brief and schema with the key header',
      () async {
        late AiHttpRequest captured;
        final analyzer = _analyzer((request) async {
          captured = request;
          return AiHttpResponse(
            statusCode: 200,
            body: _geminiEnvelope(_payload()),
          );
        });

        await analyzer.analyze(brief: 'FAMILY BRIEF');

        final body = jsonDecode(captured.body) as Map<String, dynamic>;
        expect(captured.headers['x-goog-api-key'], _validKey);
        expect(
          captured.uri.toString(),
          contains('/models/gemini-test:generateContent'),
        );
        expect(body['systemInstruction']['parts'][0]['text'], 'SYSTEM PROMPT');
        expect(body['contents'][0]['parts'][0]['text'], 'FAMILY BRIEF');
        expect(
          body['generationConfig']['responseMimeType'],
          'application/json',
        );
        expect(
          body['generationConfig']['responseSchema']['required'],
          contains('observations'),
        );
      },
    );

    test('parses a JSON envelope and maps tones', () async {
      final analyzer = _analyzer(
        (_) async =>
            AiHttpResponse(statusCode: 200, body: _geminiEnvelope(_payload())),
      );

      final analysis = await analyzer.analyze(brief: 'BRIEF');

      expect(analysis.headline, contains('steady week'));
      expect(analysis.observations, hasLength(3));
      expect(analysis.observations.first.tone, 'attention');
      expect(analysis.observations[1].tone, 'positive');
      expect(analysis.suggestions, hasLength(3));
      expect(analysis.conversationStarters, hasLength(3));
    });

    test('tolerates markdown fences around the JSON', () async {
      final fenced = '```json\n${jsonEncode(_payload())}\n```';
      final analyzer = _analyzer(
        (_) async =>
            AiHttpResponse(statusCode: 200, body: _geminiEnvelope(fenced)),
      );

      final analysis = await analyzer.analyze(brief: 'BRIEF');
      expect(analysis.summary, contains('balanced'));
    });

    test('maps rate limits and auth failures to typed errors', () async {
      for (final status in [429, 401]) {
        final analyzer = _analyzer(
          (_) async => AiHttpResponse(
            statusCode: status,
            body: jsonEncode({
              'error': {'message': 'provider detail'},
            }),
          ),
        );

        await expectLater(
          analyzer.analyze(brief: 'BRIEF'),
          throwsA(
            isA<GeminiException>().having(
              (error) => error.kind,
              'kind',
              status == 429
                  ? GeminiErrorKind.rateLimited
                  : GeminiErrorKind.unauthorized,
            ),
          ),
        );
      }
    });

    test('treats an incomplete payload as invalid', () async {
      final analyzer = _analyzer(
        (_) async => AiHttpResponse(
          statusCode: 200,
          body: _geminiEnvelope({
            'headline': 'Only a headline',
            'summary': 'No observations.',
          }),
        ),
      );

      await expectLater(
        analyzer.analyze(brief: 'BRIEF'),
        throwsA(
          isA<GeminiException>().having(
            (error) => error.kind,
            'kind',
            GeminiErrorKind.invalidResponse,
          ),
        ),
      );
    });
  });

  group('Analyzer fallback', () {
    test('uses the local report when no key is configured', () async {
      final service = AiAnalyzerService(localLatency: Duration.zero);
      final outcome = await service.analyze(DemoData.build().children.first);

      expect(outcome.usedModel, isFalse);
      expect(outcome.notice, isNull);
      expect(outcome.report.fromModel, isFalse);
      expect(outcome.report.suggestions, hasLength(3));
    });

    test('reports a malformed key without making a request', () async {
      var called = false;
      final service = AiAnalyzerService(
        apiKey: 'short',
        localLatency: Duration.zero,
        clientBuilder: (_) {
          called = true;
          return _analyzer((_) async => throw StateError('should not run'));
        },
      );

      final outcome = await service.analyze(DemoData.build().children.first);

      expect(called, isFalse);
      expect(outcome.usedModel, isFalse);
      expect(outcome.notice, contains('too short'));
    });

    test('trends analysis never calls the model transport', () async {
      var called = false;
      final service = AiAnalyzerService(
        apiKey: _validKey,
        localLatency: Duration.zero,
        clientBuilder: (_) {
          called = true;
          return _analyzer((_) async => throw StateError('should not run'));
        },
      );

      final outcome = await service.analyze(
        DemoData.build().children.first,
        includeAppDetail: false,
      );

      expect(called, isFalse);
      expect(outcome.usedModel, isFalse);
      expect(outcome.notice, isNull);
      expect(outcome.report.drivers, isEmpty);
    });

    test(
      'rejects a key with disallowed characters before any request',
      () async {
        var called = false;
        final service = AiAnalyzerService(
          apiKey: 'AIzaSyDemoKeyWith!BadChars1234567890',
          localLatency: Duration.zero,
          clientBuilder: (_) {
            called = true;
            return _analyzer((_) async => throw StateError('should not run'));
          },
        );

        final outcome = await service.analyze(DemoData.build().children.first);

        expect(called, isFalse);
        expect(outcome.usedModel, isFalse);
        expect(outcome.notice, isNotNull);
      },
    );

    test('returns a model report on success', () async {
      final service = _service(
        (_) async =>
            AiHttpResponse(statusCode: 200, body: _geminiEnvelope(_payload())),
      );

      final outcome = await service.analyze(DemoData.build().children.first);

      expect(outcome.usedModel, isTrue);
      expect(outcome.notice, isNull);
      expect(outcome.report.fromModel, isTrue);
      expect(outcome.report.headline, contains('steady week'));
      expect(outcome.report.drivers, isNotEmpty);
      // The model copy replaces the local observations.
      expect(outcome.report.observations.first.tag, 'Today');
    });

    test('falls back to the local report on a provider error', () async {
      final service = _service(
        (_) async => AiHttpResponse(
          statusCode: 503,
          body: jsonEncode({
            'error': {'message': 'temporarily unavailable'},
          }),
        ),
      );

      final outcome = await service.analyze(DemoData.build().children.first);

      expect(outcome.usedModel, isFalse);
      expect(outcome.report.fromModel, isFalse);
      expect(outcome.notice, contains('unavailable'));
    });

    test('falls back on a timeout', () async {
      final service = _service((_) async => throw TimeoutException('slow'));

      final outcome = await service.analyze(DemoData.build().children.first);

      expect(outcome.usedModel, isFalse);
      expect(outcome.notice, contains('too long'));
    });

    test('falls back on an unexpected transport exception', () async {
      final service = _service((_) async => throw StateError('boom'));

      final outcome = await service.analyze(DemoData.build().children.first);

      expect(outcome.usedModel, isFalse);
      expect(outcome.notice, contains('unexpectedly'));
    });
  });
}
