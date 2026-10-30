part of '../settings_sheet.dart';

/// Signed-in account header shown directly under the sheet title.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.accent,
  });

  final String name;
  final String subtitle;
  final String initials;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SmallAvatar(initials: initials, color: accent, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const DemoPill(icon: null),
        ],
      ),
    );
  }
}

/// Gemini key management plus the transparency entry points that show what
/// leaves the device. Parent mode only.
class _AiAnalyzerSection extends StatelessWidget {
  const _AiAnalyzerSection({
    required this.hasKey,
    required this.onEditKey,
    required this.onShowPrompt,
    required this.onShowPrivacy,
  });

  final bool hasKey;
  final VoidCallback onEditKey;
  final VoidCallback onShowPrompt;
  final VoidCallback onShowPrivacy;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsSectionLabel(strings.aiAnalyzerSection),
        const SizedBox(height: 9),
        Material(
          color: Colors.transparent,
          child: Semantics(
            button: true,
            label: hasKey
                ? strings.manageGeminiApiKey
                : strings.connectGeminiApiKey,
            onTap: onEditKey,
            excludeSemantics: true,
            child: InkWell(
              onTap: onEditKey,
              excludeFromSemantics: true,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.violetSoft,
                      AppColors.violetSoft.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const IconBubble(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.violet,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasKey
                                ? strings.geminiKeySavedTitle
                                : strings.connectYourGeminiKey,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasKey
                                ? strings.geminiCallsOnlyRefresh
                                : strings.geminiKeyOptionalHint,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 10.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.violet,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          onTap: onShowPrompt,
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(
            icon: Icons.description_outlined,
            color: AppColors.sky,
            size: 38,
          ),
          title: Text(
            strings.whatGeminiSees,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            strings.whatGeminiSeesSubtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subtle,
          ),
          dense: true,
        ),
        const SizedBox(height: 4),
        ListTile(
          onTap: onShowPrivacy,
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(
            icon: Icons.lock_outline_rounded,
            color: AppColors.mint,
            size: 38,
          ),
          title: Text(
            strings.privacyReceipt,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            strings.privacyReceiptSubtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subtle,
          ),
          dense: true,
        ),
      ],
    );
  }
}

/// Local notification preferences. Parent mode only.
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.includeParentUsage,
    required this.onIncludeParentUsageChanged,
  });

  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final bool includeParentUsage;
  final ValueChanged<bool> onIncludeParentUsageChanged;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsSectionLabel(strings.preferencesSection),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.violet,
          title: Text(
            strings.weeklyCheckInReminder,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            strings.weeklyCheckInReminderSubtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          secondary: const IconBubble(
            icon: Icons.event_available_outlined,
            color: AppColors.mint,
            size: 38,
          ),
        ),
        SwitchListTile.adaptive(
          value: includeParentUsage,
          onChanged: onIncludeParentUsageChanged,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.violet,
          title: Text(
            strings.includeMyScreenTime,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            strings.includeMyScreenTimeSubtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
          secondary: const IconBubble(
            icon: Icons.balance_rounded,
            color: AppColors.sky,
            size: 38,
          ),
        ),
      ],
    );
  }
}

/// Reminder that the demo shell does not enforce real parental controls.
class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.childMode});

  final bool childMode;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lemonSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lemon.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 17, color: AppColors.warning),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              childMode ? strings.childModeSafety : strings.parentModeSafety,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// About, demo reset and sign-out rows at the bottom of the sheet.
class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.childMode,
    required this.onShowAbout,
    required this.onResetDemo,
    required this.onSignOut,
    this.onExportData,
    this.onAddSibling,
    this.showAddSibling = false,
  });

  final bool childMode;
  final VoidCallback onShowAbout;
  final VoidCallback onResetDemo;
  final VoidCallback onSignOut;
  final VoidCallback? onExportData;
  final VoidCallback? onAddSibling;
  final bool showAddSibling;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: onShowAbout,
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(
            icon: Icons.info_outline_rounded,
            color: AppColors.sky,
            size: 38,
          ),
          title: Text(
            strings.aboutThisDemo,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subtle,
          ),
          dense: true,
        ),
        if (!childMode) ...[
          if (onExportData != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              onTap: onExportData,
              contentPadding: EdgeInsets.zero,
              leading: const IconBubble(
                icon: Icons.file_download_outlined,
                color: AppColors.mint,
                size: 38,
              ),
              title: Text(
                strings.exportFamilyData,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                strings.exportFamilyDataSubtitle,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtle,
              ),
              dense: true,
            ),
          ],
          if (showAddSibling && onAddSibling != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              onTap: onAddSibling,
              contentPadding: EdgeInsets.zero,
              leading: const IconBubble(
                icon: Icons.group_add_rounded,
                color: AppColors.sky,
                size: 38,
              ),
              title: Text(
                strings.addDemoSibling,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                strings.addDemoSiblingSubtitle,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtle,
              ),
              dense: true,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            onTap: onResetDemo,
            contentPadding: EdgeInsets.zero,
            leading: const IconBubble(
              icon: Icons.restart_alt_rounded,
              color: AppColors.coral,
              size: 38,
            ),
            title: Text(
              strings.resetDemoData,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            subtitle: Text(
              strings.resetDemoDataSubtitle,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.subtle,
            ),
            dense: true,
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(
            Icons.logout_rounded,
            size: 18,
            color: AppColors.coral,
          ),
          label: Text(
            childMode ? strings.exitChildView : strings.signOut,
            style: const TextStyle(color: AppColors.coral),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.coral.withValues(alpha: 0.28)),
          ),
        ),
      ],
    );
  }
}
