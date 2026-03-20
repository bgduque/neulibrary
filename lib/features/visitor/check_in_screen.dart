import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../main.dart'; // import apiService

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? _selectedReason;
  final bool _isBlocked = false; // Simulated blocked state
  bool _isCheckingIn = false;

  static const _reasons = [
    ('Reading', Icons.menu_book_rounded, Colors.blue),
    ('Research', Icons.science_rounded, Colors.orange),
    ('Computer Use', Icons.computer_rounded, Colors.teal),
    ('Studying', Icons.edit_note_rounded, Colors.purple),
  ];

  Future<void> _submitCheckIn() async {
    if (_selectedReason == null) return;
    
    setState(() => _isCheckingIn = true);
    try {
      String backendReason;
      switch (_selectedReason) {
        case 'Reading': backendReason = 'READING'; break;
        case 'Research': backendReason = 'RESEARCH'; break;
        case 'Computer Use': backendReason = 'COMPUTER_USE'; break;
        case 'Studying': backendReason = 'STUDYING'; break;
        default: backendReason = 'READING';
      }
      
      await apiService.checkIn(backendReason);
      
      if (!mounted) return;
      _showWelcomeDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check in. Please try again later.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingIn = false);
      }
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          Icons.check_circle_rounded,
          size: 72,
          color: Theme.of(ctx).colorScheme.primary,
        ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
        title: const Text(
          'Welcome to NEU Library!',
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
        content: Text(
          'Reason: $_selectedReason\nHave a productive day!',
          textAlign: TextAlign.center,
        ).animate(delay: 400.ms).fadeIn(),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: const Text('Done'),
          ).animate(delay: 600.ms).fadeIn(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isBlocked) {
      return _buildBlockedView(theme);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withAlpha(80),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/login'),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      elevation: 2,
                    ),
                  ),
                ),
              ).animate().fadeIn().slideX(begin: -0.2),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                                Icons.waving_hand_rounded,
                                size: 64,
                                color: theme.colorScheme.primary,
                              )
                              .animate()
                              .shimmer(duration: 1500.ms, delay: 500.ms)
                              .fadeIn(),
                          const SizedBox(height: 24),
                          Text(
                            'What brings you to the library today?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                          const SizedBox(height: 48),

                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: _reasons.asMap().entries.map((entry) {
                              final delay = 300 + (entry.key * 100);
                              final r = entry.value;
                              final isSelected = _selectedReason == r.$1;

                              return SizedBox(
                                    width: 150,
                                    height: 140,
                                    child: Card(
                                      elevation: isSelected ? 8 : 2,
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                          : theme.colorScheme.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: isSelected
                                            ? BorderSide(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 2,
                                              )
                                            : BorderSide.none,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => setState(
                                          () => _selectedReason = r.$1,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              r.$2,
                                              size: 48,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : r.$3,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              r.$1,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    color: isSelected
                                                        ? theme
                                                              .colorScheme
                                                              .primary
                                                        : null,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(delay: delay.ms)
                                  .fadeIn()
                                  .scale(begin: const Offset(0.8, 0.8));
                            }).toList(),
                          ),
                          const SizedBox(height: 64),

                          AnimatedOpacity(
                            opacity: _selectedReason != null ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                              width: 240,
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: (_selectedReason != null && !_isCheckingIn)
                                    ? _submitCheckIn
                                    : null,
                                icon: _isCheckingIn 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _isCheckingIn ? 'Checking In...' : 'Check In',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                            ),
                          ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedView(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                size: 96,
                color: theme.colorScheme.error,
              ).animate().shake(duration: 500.ms).color(end: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ).animate().fadeIn().slideY(),
              const SizedBox(height: 12),
              Text(
                'Your account has been restricted.\nPlease contact the Library Admin.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Login'),
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
