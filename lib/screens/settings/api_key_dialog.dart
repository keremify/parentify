part of '../settings_sheet.dart';

/// Prompts for a Gemini API key and validates it before returning it.
class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({this.initialKey});

  final String? initialKey;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialKey ?? '',
  );
  bool _obscure = true;
  String? _error;

  void _save() {
    final value = _controller.text.trim();
    final problem = AiAnalyzerService.validateApiKey(
      value,
      strings: context.strings,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(
        strings.geminiApiKey,
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.apiKeySessionBody,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: strings.apiKeyLabel,
                hintText: 'AIza…',
                prefixIcon: const Icon(Icons.key_rounded, size: 18),
                suffixIcon: IconButton(
                  tooltip: _obscure ? strings.showApiKey : strings.hideApiKey,
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              strings.apiKeyEnvHint,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtle,
              ),
            ),
            if (widget.initialKey != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                  child: Text(strings.removeKey),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text(strings.saveKey),
        ),
      ],
    );
  }
}
