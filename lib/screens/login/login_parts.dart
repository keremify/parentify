part of '../login_screen.dart';

class _RoleSwitch extends StatelessWidget {
  const _RoleSwitch({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final option in UserRole.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: role == option,
                label: option == UserRole.parent
                    ? context.strings.signInAsParent
                    : context.strings.signInAsChild,
                onTap: () => onChanged(option),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: role == option
                          ? AppColors.ink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: role == option
                          ? [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option == UserRole.parent
                              ? Icons.supervisor_account_rounded
                              : Icons.face_rounded,
                          size: 17,
                          color: role == option
                              ? Colors.white
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          option == UserRole.parent
                              ? context.strings.parentRole
                              : context.strings.childRole,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: role == option
                                ? Colors.white
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChildChoice extends StatelessWidget {
  const _ChildChoice({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final Child child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: context.strings.signInAsChildName(child.name),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? child.accent.withValues(alpha: 0.13)
                : AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? child.accent.withValues(alpha: 0.55)
                  : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ChildAvatar(child: child, size: 36, showDeviceBadge: false),
                  if (selected)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: child.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.paper,
                            width: 1.4,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                child.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.violet),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary sign-in action, extracted so the screen's `build` stays shallow.
///
/// The busy and idle states are separate widgets rather than a nested ternary
/// chain; only the label and the arrow switch.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.busy,
    required this.role,
    required this.onPressed,
  });

  final bool busy;
  final UserRole role;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: busy ? const _SubmitBusy() : _SubmitIdle(role: role),
      ),
    );
  }
}

class _SubmitBusy extends StatelessWidget {
  const _SubmitBusy();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('busy'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Text(context.strings.signingIn),
      ],
    );
  }
}

class _SubmitIdle extends StatelessWidget {
  const _SubmitIdle({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final label = role == UserRole.parent
        ? context.strings.enterFamilySpace
        : context.strings.openMyActivity;

    return FittedBox(
      key: const ValueKey('idle'),
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }
}

/// Demo hint, optional one-tap entry point, feature strip and footer.
class _SignInFooter extends StatelessWidget {
  const _SignInFooter({
    required this.role,
    required this.busy,
    required this.demoAuthAvailable,
    required this.onDemoPressed,
  });

  final UserRole role;
  final bool busy;
  final bool demoAuthAvailable;
  final VoidCallback onDemoPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DemoHint(role: role),
        if (demoAuthAvailable) ...[
          const SizedBox(height: 2),
          TextButton(
            onPressed: busy ? null : onDemoPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 48),
            ),
            child: Text(
              role == UserRole.parent
                  ? context.strings.useDemoAccount
                  : context.strings.useDemoPin,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.violet,
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        const _FeatureStrip(),
        Center(
          child: Text(
            context.strings.loginFooter,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtle.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: AppColors.subtle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            role == UserRole.parent
                ? context.strings.parentDemoHint
                : context.strings.childDemoHint,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.subtle,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniFeature(
              icon: Icons.schedule_rounded,
              label: context.strings.featureScreenTime,
            ),
          ),
          Expanded(
            child: _MiniFeature(
              icon: Icons.grid_view_rounded,
              label: context.strings.featureAppInsights,
            ),
          ),
          Expanded(
            child: _MiniFeature(
              icon: Icons.auto_awesome_rounded,
              label: context.strings.featureAiCheckIns,
            ),
          ),
        ],
      ),
    );
  }
}
