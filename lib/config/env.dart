import 'package:flutter/services.dart';

import '../services/gemini_prompt.dart';

/// Values parsed from `assets/env.defaults`.
///
/// The demo ships with this file as an asset, so editing a value and restarting
/// the app is enough to change it. It is checked in and must stay keyless: a
/// real `GEMINI_API_KEY` belongs in a `--dart-define` or the in-app Settings
/// sheet, never in a bundled file. A `--dart-define` with the same name still
/// wins at compile time, which keeps CI and release builds overridable without
/// touching the file.
class EnvValues {
  const EnvValues._(this._values);

  const EnvValues.empty() : _values = const {};

  final Map<String, String> _values;

  String? operator [](String key) => _values[key];

  bool get isEmpty => _values.isEmpty;

  Map<String, String> get entries => Map.unmodifiable(_values);
}

/// Parses a dotenv-style file.
///
/// Supported syntax is deliberately small: `KEY=value`, blank lines, `#` or
/// `;` comments, an optional `export` prefix, and single or double quotes
/// around values. `\n` and `\t` inside a value are unescaped so a prompt can
/// live on one line when needed.
EnvValues parseEnvFile(String contents) {
  final values = <String, String>{};

  for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
    var line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
      continue;
    }
    if (line.startsWith('export ')) {
      line = line.substring('export '.length).trimLeft();
    }

    final separator = line.indexOf('=');
    if (separator <= 0) continue;

    final key = line.substring(0, separator).trim();
    if (key.isEmpty) continue;

    var value = line.substring(separator + 1).trim();
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        value = value.substring(1, value.length - 1);
      }
    }
    values[key] = value.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
  }

  return EnvValues._(values);
}

/// Process-wide demo configuration.
///
/// [load] runs once during bootstrap. Until then every getter returns its
/// built-in demo default, which keeps widget tests and direct `AppState()`
/// construction working without a binding.
class AppEnv {
  static EnvValues _values = const EnvValues.empty();
  static String? _promptFile;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static Future<void> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;

    try {
      final raw = await assets.loadString(_configAsset);
      _values = parseEnvFile(raw);
    } catch (_) {
      // A missing config asset falls back to the compiled defaults below. The
      // demo stays runnable even if the asset is removed by a custom build.
      _values = const EnvValues.empty();
    }

    try {
      _promptFile = (await assets.loadString(_promptAsset)).trim();
    } catch (_) {
      _promptFile = null;
    }

    _loaded = true;
  }

  /// Replaces the current configuration. Intended for tests.
  static void use(EnvValues values, {String? systemPrompt}) {
    _values = values;
    _promptFile = systemPrompt;
    _loaded = true;
  }

  static void reset() {
    _values = const EnvValues.empty();
    _promptFile = null;
    _loaded = false;
  }

  static const _configAsset = 'assets/env.defaults';
  static const _promptAsset = 'assets/prompts/gemini_system_prompt.txt';

  static const _defineApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _defineModel = String.fromEnvironment('GEMINI_MODEL');
  static const _defineApiUrl = String.fromEnvironment('GEMINI_API_URL');
  static const _defineTimeout = String.fromEnvironment(
    'AI_REQUEST_TIMEOUT_SECONDS',
  );
  static const _defineMaxTokens = String.fromEnvironment(
    'AI_MAX_OUTPUT_TOKENS',
  );
  static const _defineParentEmail = String.fromEnvironment('DEMO_PARENT_EMAIL');
  static const _defineParentPassword = String.fromEnvironment(
    'DEMO_PARENT_PASSWORD',
  );
  static const _defineChildPin = String.fromEnvironment('DEMO_CHILD_PIN');

  static String _resolve(String key, String fallback, String define) {
    if (define.trim().isNotEmpty) return define.trim();
    final value = _values[key]?.trim();
    if (value == null || value.isEmpty) return fallback;
    return value;
  }

  static String get geminiApiKey =>
      _resolve('GEMINI_API_KEY', '', _defineApiKey);

  static String get geminiModel {
    const fallback = 'gemini-2.5-flash';
    final resolved = _resolve('GEMINI_MODEL', fallback, _defineModel);
    final safe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$');
    return safe.hasMatch(resolved) ? resolved : fallback;
  }

  static String get geminiApiUrl {
    const fallback = 'https://generativelanguage.googleapis.com/v1beta';
    final resolved = _resolve('GEMINI_API_URL', fallback, _defineApiUrl);
    final uri = Uri.tryParse(resolved);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return fallback;
    }
    return resolved;
  }

  static Duration get aiTimeout {
    final seconds = int.tryParse(
      _resolve('AI_REQUEST_TIMEOUT_SECONDS', '25', _defineTimeout),
    );
    final safe = (seconds ?? 25).clamp(5, 120);
    return Duration(seconds: safe);
  }

  static int get aiMaxOutputTokens {
    final tokens = int.tryParse(
      _resolve('AI_MAX_OUTPUT_TOKENS', '900', _defineMaxTokens),
    );
    return (tokens ?? 900).clamp(256, 4096);
  }

  static String get demoParentEmail =>
      _resolve('DEMO_PARENT_EMAIL', 'parent@parentify.dev', _defineParentEmail);

  static String get demoParentPassword =>
      _resolve('DEMO_PARENT_PASSWORD', 'Parentify2026!', _defineParentPassword);

  static String get demoChildPin =>
      _resolve('DEMO_CHILD_PIN', '2026', _defineChildPin);

  /// A readable prompt asset wins by default; `GEMINI_SYSTEM_PROMPT` in
  /// `.env` can replace it without touching code.
  static String get geminiSystemPrompt {
    final override = _values['GEMINI_SYSTEM_PROMPT']?.trim();
    if (override != null && override.isNotEmpty) return override;
    final file = _promptFile;
    if (file != null && file.isNotEmpty) return file;
    return defaultGeminiSystemPrompt;
  }
}
