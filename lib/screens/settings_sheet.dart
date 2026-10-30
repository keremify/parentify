import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../config/env.dart';
import '../data/demo_data.dart';
import '../l10n/app_strings.dart';
import '../models/visibility.dart';
import '../services/ai_analyzer_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

part 'settings/section_label.dart';
part 'settings/api_key_dialog.dart';
part 'settings/settings_sections.dart';

Future<void> showParentifySettings(
  BuildContext context, {
  bool childMode = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.ink.withValues(alpha: 0.42),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _SettingsSheet(childMode: childMode),
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.childMode});

  final bool childMode;

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  Future<void> _editApiKey() async {
    final state = AppScope.read(context);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _ApiKeyDialog(initialKey: state.ai.apiKey),
    );
    if (result == null || !mounted) return;

    final problem = state.saveApiKey(
      result.trim().isEmpty ? null : result,
      strings: context.strings,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          problem ??
              (result.trim().isEmpty
                  ? context.strings.aiKeyRemoved
                  : context.strings.geminiKeySaved),
        ),
      ),
    );
  }

  void _signOut() {
    final state = AppScope.read(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.popUntil((route) => route.isFirst);
    state.signOut();
  }

  void _showPromptPreview() {
    final state = AppScope.read(context);
    final child =
        state.activeChild ??
        (state.children.isEmpty ? null : state.children.first);
    if (child == null) return;
    final prompt = AiAnalyzerService.buildPrompt(
      child,
      notes: state.notesFor(child.id),
      agreement: state.activeAgreementFor(child.id),
      lastCheckIn: state.lastCheckIn,
      includeAppDetail:
          !state.isChild &&
          state.visibilityFor(child.id) != VisibilityLevel.trends,
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.strings.whatGeminiSeesForChild(child.name),
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: SelectableText(
              '${context.strings.systemPromptLabel}\n\n'
              '${AppEnv.geminiSystemPrompt}\n\n'
              '────────────────────\n\n'
              '${context.strings.familyBriefLabel}\n\n$prompt',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.strings.close),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.strings.resetDemoDataQuestion,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.strings.resetDemoDataBody,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12.5,
            height: 1.55,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.strings.keepData),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.strings.reset),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final state = AppScope.read(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.popUntil((route) => route.isFirst);
    await state.resetDemoData();
  }

  void _showPrivacyReceipt() {
    final state = AppScope.read(context);
    final strings = context.strings;
    final lines = state.children
        .map((child) {
          final notes = state.notesFor(child.id).length;
          final level = state.visibilityFor(child.id);
          return strings.privacyLine(
            child.name,
            strings.visibilityLabel(level).toLowerCase(),
            notes,
          );
        })
        .join('\n');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.strings.whatIsShared,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          context.strings.privacyBody(lines),
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            height: 1.55,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.strings.gotIt),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    final state = AppScope.read(context);
    final strings = context.strings;
    final jsonMap = state.exportFamilyData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          strings.exportDialogTitle,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.exportDialogBody,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.close),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.copiedToClipboard),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: Text(strings.copyJson),
          ),
        ],
      ),
    );
  }

  Future<void> _addSibling() async {
    final state = AppScope.read(context);
    final strings = context.strings;
    await state.saveChild(DemoData.buildAdaChild(), pin: '2026');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.addedSibling),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const BrandLockup(markSize: 32),
        content: Text(
          context.strings.aboutDemoBody,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            height: 1.6,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.strings.gotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final state = AppScope.of(context);
    final profileName = widget.childMode
        ? state.activeChild?.name ?? strings.childFallback
        : state.parentName;
    final profileInitials = widget.childMode
        ? state.activeChild?.initials ?? '?'
        : state.parentName.isEmpty
        ? '?'
        : state.parentName.substring(0, 1).toUpperCase();
    final profileSubtitle = widget.childMode
        ? strings.childProfileSharedDemo
        : strings.parentAccount(state.familyName);
    final hasKey = state.ai.hasApiKey;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                strings.settings,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
                size: 38,
                background: AppColors.cream,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileCard(
            name: profileName,
            subtitle: profileSubtitle,
            initials: profileInitials,
            accent: widget.childMode
                ? state.activeChild?.accent ?? AppColors.violet
                : AppColors.violet,
          ),
          if (!widget.childMode) ...[
            const SizedBox(height: 26),
            _AiAnalyzerSection(
              hasKey: hasKey,
              onEditKey: _editApiKey,
              onShowPrompt: _showPromptPreview,
              onShowPrivacy: _showPrivacyReceipt,
            ),
            const SizedBox(height: 22),
            _PreferencesSection(
              notificationsEnabled: state.notificationsEnabled,
              onNotificationsChanged: state.setNotificationsEnabled,
              includeParentUsage: state.includeParentUsage,
              onIncludeParentUsageChanged: state.setIncludeParentUsage,
            ),
          ],
          const SizedBox(height: 20),
          _SafetyNote(childMode: widget.childMode),
          const SizedBox(height: 14),
          _AccountActions(
            childMode: widget.childMode,
            onShowAbout: _showAbout,
            onResetDemo: _resetDemo,
            onSignOut: _signOut,
            onExportData: _exportData,
            onAddSibling: _addSibling,
            showAddSibling: state.children.length == 1,
          ),
        ],
      ),
    );
  }
}
