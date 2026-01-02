import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';
import 'overview_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bgColor = Color(0xFF0A0A0A);
  static const _dialogBgColor = Color(0xFF1A1A1A);
  static const _pagePadding = EdgeInsets.all(24);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _customHostController = TextEditingController();

  bool _rememberMe = true;
  bool _showAdvanced = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultHost();
  }

  Future<void> _loadDefaultHost() async {
    final authProvider = context.read<AuthProvider>();
    _customHostController.text = authProvider.currentHost;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _customHostController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      prefixIcon: Icon(prefixIcon, color: Colors.white70),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (!_rememberMe) {
      Logger.log(
        'User disabled remember me, showing warning',
        tag: 'LoginScreen',
      );

      final shouldContinue = await _showNoSaveWarning();
      if (!shouldContinue || !mounted) {
        Logger.log('User cancelled login after warning', tag: 'LoginScreen');
        return;
      }
    }

    Logger.log('Starting login process', tag: 'LoginScreen');
    _setLoading(true);

    // Show loading snackbar
    CustomSnackbar.loading(
      context,
      title: 'Signing In',
      description: 'Please wait...',
      key: 'login',
    );

    final authProvider = context.read<AuthProvider>();

    // Update custom host if advanced settings are shown and URL is provided
    if (_showAdvanced && _customHostController.text.trim().isNotEmpty) {
      final customUrl = _customHostController.text.trim();
      if (customUrl != authProvider.currentHost) {
        Logger.log('Updating custom host from login screen', tag: 'LoginScreen');
        await authProvider.setCustomHost(customUrl);
      }
    }

    final success = await authProvider.loginWithCredentials(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    _setLoading(false);
    if (!mounted) return;

    // Dismiss loading snackbar
    CustomSnackbar.dismiss('login');

    if (success) {
      Logger.log(
        'Login successful, navigating to overview',
        tag: 'LoginScreen',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OverviewScreen()),
        (route) => false,
      );
      return;
    }

    Logger.error('Login failed, showing error to user', tag: 'LoginScreen');
    CustomSnackbar.error(
      context,
      title: 'Login Failed',
      description: authProvider.error ?? 'Please check your credentials',
    );
  }

  Future<bool> _showNoSaveWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text(
          'Not Saving Login?',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You will need to login every time you open the app.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'It is highly recommended to enable "Remember me" for a better experience.',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _rememberMe = true);
              Navigator.of(context).pop(false);
            },
            child: const Text(
              'Enable Remember Me',
              style: TextStyle(color: Colors.green),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleBack() async {
    Logger.log('User navigating back to onboarding', tag: 'LoginScreen');
    await StorageService().setOnboardingComplete(false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rememberBg = _rememberMe
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.orange.withValues(alpha: 0.1);

    final rememberBorder = _rememberMe
        ? Colors.green.withValues(alpha: 0.3)
        : Colors.orange.withValues(alpha: 0.3);

    final canGoBack = Navigator.of(context).canPop();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await StorageService().setOnboardingComplete(false);
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: _handleBack,
                )
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: _pagePadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/os/Icon512.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your credentials to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Remember me
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: rememberBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: rememberBorder),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.white.withValues(alpha: 0.3);
                          }),
                          checkColor: Colors.black,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remember me on this device',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rememberMe
                                    ? 'Your credentials will be saved securely'
                                    : 'Recommended: Stay signed in for easy access',
                                style: TextStyle(
                                  color: _rememberMe
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advanced Settings toggle
                  TextButton(
                    onPressed: () =>
                        setState(() => _showAdvanced = !_showAdvanced),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showAdvanced ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Advanced Settings',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  if (_showAdvanced) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customHostController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Custom Server Host',
                        prefixIcon: Icons.dns,
                        hintText: ApiClient.defaultBaseUrl,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return null;

                        final uri = Uri.tryParse(v);
                        if (uri == null || !uri.hasScheme) {
                          return 'Please enter a valid URL (e.g., https://api.example.com)';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Sign in button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
