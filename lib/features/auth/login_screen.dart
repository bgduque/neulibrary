import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../main.dart' show authService;
import '../../core/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final result = await authService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case AuthResult.success:
        final user = authService.currentUser!;
        if (user.isAdmin) {
          context.go('/admin');
        } else if (user.setupComplete) {
          context.go('/check-in');
        } else {
          context.go('/onboarding');
        }
      case AuthResult.invalidDomain:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use your @neu.edu.ph email to sign in.'),
            backgroundColor: Colors.red,
          ),
        );
      case AuthResult.cancelled:
        break; // User dismissed the popup.
      case AuthResult.error:
        final errorMsg = authService.lastError ?? 'Unknown error';
        debugPrint('[LoginScreen] Sign-in error: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primary,
              const Color(0xFF004D40), // Deep Teal / Green
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surface.withAlpha(240),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 48,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Logo
                      Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(26),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_library_rounded,
                              size: 72,
                              color: theme.colorScheme.primary,
                            ),
                          )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 600.ms),
                      const SizedBox(height: 24),

                      // Animated Title
                      Text(
                            'NEU Library',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                          .animate()
                          .slideY(
                            begin: 0.3,
                            duration: 600.ms,
                            curve: Curves.easeOutQuad,
                          )
                          .fadeIn(duration: 600.ms),
                      const SizedBox(height: 8),

                      Text(
                            'Visitor Log System',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                          .animate(delay: 200.ms)
                          .slideY(
                            begin: 0.3,
                            duration: 600.ms,
                            curve: Curves.easeOutQuad,
                          )
                          .fadeIn(duration: 600.ms),
                      const SizedBox(height: 48),

                      // Animated Primary Login Button
                      SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : _handleGoogleSignIn,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(
                                _isLoading
                                    ? 'Signing in…'
                                    : 'Sign in with Google',
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                          .animate(delay: 400.ms)
                          .slideY(
                            begin: 0.3,
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          )
                          .fadeIn(duration: 500.ms),

                      const SizedBox(height: 32),
                      Text(
                        'Use your institutional Google email to sign in.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 800.ms).fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
