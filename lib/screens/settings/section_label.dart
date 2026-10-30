part of '../settings_sheet.dart';

/// Small all-caps heading used to group rows inside the sheet.
class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: AppColors.subtle,
      ),
    );
  }
}
