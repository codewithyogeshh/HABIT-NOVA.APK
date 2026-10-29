import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synvero/app/theme/app_colors.dart';
import 'package:synvero/core/widgets/mountain_illustration.dart';
import 'package:synvero/core/widgets/synvero_logo.dart';

/// Login screen widget.
///
/// Implements Screen 1 from the Synvero UI design mockup:
/// - Synvero sprout logo with tagline
/// - Welcome Back header
/// - Email & Password inputs with rounded container styling
/// - Forgot Password right-aligned link
/// - "Log In ->" action button with loading state
/// - "Don't have an account? Create Account" routing
/// - Atmospheric mountain vector illustration anchored at the bottom
class LoginScreen extends StatefulWidget {
  /// Callback invoked when the user taps the login button with valid input.
  final Future<void> Function(String email, String password)? onLogin;

  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.onLogin != null) {
        await widget.onLogin!(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // No auth backend configured yet. Simulate a delay so the
        // loading state is visible, then show a helpful message.
        await Future<void>.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _errorMessage =
                'Authentication backend is not configured yet. '
                'Please configure Supabase to enable real login.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final raw = e.toString().toLowerCase();
          if (raw.contains('invalid login credentials') ||
              raw.contains('invalid_credentials') ||
              raw.contains('invalid email or password')) {
            _errorMessage = 'Invalid email or password.\nIf you don\'t have an account yet, please register first then log in.';
          } else if (raw.contains('user not found') || raw.contains('user_not_found')) {
            _errorMessage = 'No account found with this email. Please register first then log in.';
          } else if (raw.contains('invalid email') || raw.contains('invalid_email')) {
            _errorMessage = 'Invalid email address. Please check your email or register first.';
          } else if (raw.contains('email not confirmed')) {
            _errorMessage = 'Please confirm your email address before signing in.';
          } else if (raw.contains('rate limit')) {
            _errorMessage = 'Too many attempts. Please try again in a few moments.';
          } else if (e is AuthException) {
            _errorMessage = e.message;
          } else {
            final clean = e.toString()
                .replaceAll('AuthException: ', '')
                .replaceAll('AuthApiException: ', '')
                .replaceAll('Exception: ', '')
                .replaceAll('Login failed: ', '');
            _errorMessage = clean;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainBackground,
      body: Stack(
        children: [
          // Mountain landscape illustration at the bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MountainIllustration(height: 140),
          ),

          // Main form content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        // Synvero Brand Logo (Emblem + Name + Tagline)
                        const SynveroLogo(
                          iconSize: 48,
                          titleFontSize: 26,
                          taglineFontSize: 13,
                        ),

                        const SizedBox(height: 36),

                        // Section Heading
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: kDarkText,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Log in to continue your journey.',
                          style: TextStyle(
                            color: kSecondaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Email Address Field
                        const Text(
                          'Email address',
                          style: TextStyle(
                            color: kDarkText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: kSecondaryText,
                            ),
                            filled: true,
                            fillColor: kInputBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: kPrimaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 18),

                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: kDarkText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: kSecondaryText,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: kSecondaryText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: kInputBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: kBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: kPrimaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),

                        const SizedBox(height: 8),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset link will be sent to your email.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kErrorColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: kErrorColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: kErrorColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: kErrorColor,
                                          fontSize: 13,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errorMessage!.toLowerCase().contains('register')) ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushNamed('/signup');
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '👉 Register new account now',
                                            style: TextStyle(
                                              color: kPrimaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded, size: 13, color: kPrimaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Log In -> Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  kPrimaryColor.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Create Account Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: kSecondaryText,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/signup');
                              },
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),
                      ],
                    ),
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