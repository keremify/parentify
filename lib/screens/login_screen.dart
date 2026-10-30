import 'package:flutter/material.dart';

import '../models/child.dart';
import '../l10n/app_strings.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_backdrop.dart';
import '../widgets/brand.dart';
import '../widgets/child_avatar.dart';

part 'login/login_parts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();

  UserRole _role = UserRole.parent;
  String? _selectedChildId;
  bool _obscurePassword = true;
  bool _busy = false;
  bool _emailPrefilled = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emailPrefilled) return;
    _emailPrefilled = true;
    // The demo email is not a secret; the password intentionally stays empty.
    _emailController.text = AppScope.read(context).parentEmail;
  }

  @override
  void dispose() {
    _intro.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _reveal({
    required Widget child,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.055),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    final state = AppScope.read(context);
    final isChildSignIn = _role == UserRole.child;
    final child = state.childById(
      _selectedChildId ??
          (state.children.isEmpty ? '' : state.children.first.id),
    );

    if (isChildSignIn && child == null) {
      _showMessage(context.strings.missingChildProfile);
      return;
    }
    if (!isChildSignIn &&
        (_emailController.text.trim().isEmpty ||
            _passwordController.text.isEmpty)) {
      _showMessage(context.strings.enterParentCredentials);
      return;
    }

    await _runSignIn(
      state,
      isChildSignIn
          ? () => state.signInChild(
              childId: child!.id,
              pin: _pinController.text,
              strings: context.strings,
            )
          : () => state.signInParent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              strings: context.strings,
            ),
    );
  }

  Future<void> _signInDemo() async {
    if (_busy) return;
    final state = AppScope.read(context);
    final child = state.childById(
      _selectedChildId ??
          (state.children.isEmpty ? '' : state.children.first.id),
    );

    if (_role == UserRole.child && child == null) {
      _showMessage(context.strings.missingChildProfile);
      return;
    }

    await _runSignIn(
      state,
      _role == UserRole.child
          ? () => state.signInDemoChild(childId: child!.id)
          : state.signInDemoParent,
    );
  }

  Future<void> _runSignIn(
    AppState state,
    Future<bool> Function() signIn,
  ) async {
    setState(() => _busy = true);
    FocusScope.of(context).unfocus();
    final ok = await signIn();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      _showMessage(state.authError ?? context.strings.signInFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final children = state.children;
    final selectedChild = children.isEmpty
        ? null
        : children.firstWhere(
            (child) => child.id == (_selectedChildId ?? children.first.id),
            orElse: () => children.first,
          );

    return Scaffold(
      body: AmbientBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewport.maxHeight - 38,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reveal(
                            start: 0,
                            end: 0.35,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: BrandLockup(markSize: 38),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.paper.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 11,
                                        color: AppColors.muted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.strings.localDemo,
                                        style: const TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          _reveal(
                            start: 0.06,
                            end: 0.48,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.violet,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      context.strings.loginTagline,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: AppColors.violet,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            context.strings.loginHeadlineStart,
                                      ),
                                      TextSpan(
                                        text:
                                            context.strings.loginHeadlineAccent,
                                        style: const TextStyle(
                                          color: AppColors.violet,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      TextSpan(
                                        text: context.strings.loginHeadlineEnd,
                                      ),
                                    ],
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 36,
                                    height: 1.12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.3,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                Text(
                                  context.strings.loginSubtitle,
                                  style: const TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 13.5,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          _reveal(
                            start: 0.18,
                            end: 0.65,
                            child: _RoleSwitch(
                              role: _role,
                              onChanged: (role) => setState(() => _role = role),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _reveal(
                            start: 0.28,
                            end: 0.8,
                            child: _buildForm(
                              state: state,
                              selectedChild: selectedChild,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _reveal(
                            start: 0.4,
                            end: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SubmitButton(
                                  busy: _busy,
                                  role: _role,
                                  onPressed: _submit,
                                ),
                                const SizedBox(height: 12),
                                _SignInFooter(
                                  role: _role,
                                  busy: _busy,
                                  demoAuthAvailable: state.demoAuthAvailable,
                                  onDemoPressed: _signInDemo,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required AppState state, required Child? selectedChild}) {
    if (_role == UserRole.parent) {
      return Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              labelText: context.strings.parentEmailLabel,
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              labelText: context.strings.passwordLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? context.strings.showPassword
                    : context.strings.hidePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.strings.whoIsCheckingIn,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.muted,
            ),
          ),
        ),
        if (selectedChild == null)
          Text(
            context.strings.noChildProfiles,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              color: AppColors.muted,
            ),
          )
        else
          Row(
            children: [
              for (var index = 0; index < state.children.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ChildChoice(
                    child: state.children[index],
                    selected: state.children[index].id == selectedChild.id,
                    onTap: () => setState(
                      () => _selectedChildId = state.children[index].id,
                    ),
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 11),
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            labelText: context.strings.pinLabel,
            counterText: '',
            prefixIcon: const Icon(Icons.pin_outlined, size: 19),
          ),
        ),
      ],
    );
  }
}
