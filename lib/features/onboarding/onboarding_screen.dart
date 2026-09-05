import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kAccentColor = Color(0xFFFFBB00);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;
  bool isLogin = true;
  int registerStep = 0;
  bool showSkip = true;

  final loginController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? selectedChessLevel;

  final chessLevels = const [
    _ChessLevel(
      value: 'beginner',
      title: 'Beginner',
      description: 'I’m just getting started with chess.',
      icon: Icons.school_outlined,
    ),
    _ChessLevel(
      value: 'intermediate',
      title: 'Intermediate',
      description: 'I know the basics and play regularly.',
      icon: Icons.trending_up_rounded,
    ),
    _ChessLevel(
      value: 'advanced',
      title: 'Advanced',
      description: 'I understand strategy and complex positions.',
      icon: Icons.psychology_outlined,
    ),
    _ChessLevel(
      value: 'competitive',
      title: 'Competitive Player',
      description: 'I play seriously and may compete in tournaments.',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  @override
  void dispose() {
    loginController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep == 0) {
      if (!validateAuthStep()) return;

      setState(() {
        showSkip = false;
      });
    }

    if (currentStep == 1) {
      if (selectedChessLevel == null) {
        showMessage('Choose your chess experience first.');
        return;
      }
    }

    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      return;
    }

    finishOnboarding();
  }

  void previousStep() {
    if (currentStep == 0) return;

    setState(() {
      currentStep--;
    });
  }

  void skipAuth() {
    setState(() {
      currentStep = 1;
      showSkip = false;
    });
  }

  bool validateAuthStep() {
    if (isLogin) {
      if (loginController.text.trim().isEmpty) {
        showMessage('Enter your email or username.');
        return false;
      }

      return true;
    }

    if (registerStep == 0) {
      if (emailController.text.trim().isEmpty) {
        showMessage('Enter your email.');
        return false;
      }

      if (usernameController.text.trim().isEmpty) {
        showMessage('Choose a username.');
        return false;
      }

      setState(() {
        registerStep = 1;
      });

      return false;
    }

    if (passwordController.text.isEmpty) {
      showMessage('Enter a password.');
      return false;
    }

    if (confirmPasswordController.text.isEmpty) {
      showMessage('Confirm your password.');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Passwords do not match.');
      return false;
    }

    return true;
  }

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('chess_level', selectedChessLevel ?? 'beginner');

    if (!mounted) return;

    context.go('/play');
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void switchAuthMode(bool login) {
    if (isLogin == login) return;

    setState(() {
      isLogin = login;
      registerStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildCurrentStep(context, key: ValueKey(currentStep)),
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            _StepIndicator(number: i + 1, active: currentStep >= i),
            if (i != 2)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: currentStep > i
                      ? kAccentColor
                      : Theme.of(context).dividerColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, {Key? key}) {
    switch (currentStep) {
      case 0:
        return _buildAuthStep(context, key: key);
      case 1:
        return _buildChessStep(context, key: key);
      case 2:
        return _buildWelcomeStep(context, key: key);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAuthStep(BuildContext context, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey('${isLogin}_$registerStep'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLogin ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Sign in to continue your chess journey.'
                      : 'Create an account to keep your progress safe.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                if (isLogin)
                  _buildLoginForm(context)
                else
                  _buildRegisterForm(context),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'G',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Row(
              key: ValueKey(isLogin),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLogin
                      ? 'Don’t have an account?'
                      : 'Already have an account?',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => switchAuthMode(!isLogin),
                  child: Text(
                    isLogin ? 'Register' : 'Log in',
                    style: const TextStyle(
                      color: kAccentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return _InputField(
      controller: loginController,
      label: 'Email or username',
      hint: 'you@example.com or your_username',
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.person_outline_rounded,
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    if (registerStep == 0) {
      return Column(
        children: [
          _InputField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: usernameController,
            label: 'Username',
            hint: 'your_username',
            prefixIcon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color
                    ?.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _InputField(
          controller: passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          obscureText: obscurePassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _InputField(
          controller: confirmPasswordController,
          label: 'Confirm password',
          hint: 'Enter your password again',
          obscureText: obscureConfirmPassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Step 2 of 2',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color
                  ?.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChessStep(BuildContext context, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How strong are you?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the level that feels closest to your current chess experience.',
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Theme.of(context).textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 26),
          ...chessLevels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChessLevelCard(
                level: level,
                selected: selectedChessLevel == level.value,
                onTap: () {
                  setState(() {
                    selectedChessLevel = level.value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context, {Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 44,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'TADAM!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You’re all set.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Your chess journey starts here.\nLet’s play.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium?.color
                    ?.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final isFirstStep = currentStep == 0;
    final isFinalStep = currentStep == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
      child: isFirstStep
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: nextStep,
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: showSkip
                      ? Center(
                          key: const ValueKey('skip'),

                          child: TextButton(
                            onPressed: skipAuth,
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(
                                color: kAccentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty')),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: previousStep,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: nextStep,
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFinalStep ? 'Start playing' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.number, required this.active});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active
            ? kAccentColor
            : Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.black
                : Theme.of(context).textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.025),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccentColor, width: 2),
        ),
      ),
    );
  }
}

class _ChessLevelCard extends StatelessWidget {
  const _ChessLevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final _ChessLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? kAccentColor.withValues(alpha: 0.10)
              : theme.cardColor,
          border: Border.all(
            color: selected ? kAccentColor : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? kAccentColor
                    : theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                level.icon,
                color: selected ? Colors.black : theme.iconTheme.color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? kAccentColor : theme.dividerColor,
                  width: 2,
                ),
                color: selected ? kAccentColor : Colors.transparent,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChessLevel {
  const _ChessLevel({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String value;
  final String title;
  final String description;
  final IconData icon;
}
