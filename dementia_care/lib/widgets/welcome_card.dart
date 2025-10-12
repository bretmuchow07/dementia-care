import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';

class WelcomeCard extends StatefulWidget {
  final String? lastMood;

  const WelcomeCard({super.key, this.lastMood});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // Speak welcome message after animation starts
    Future.delayed(const Duration(milliseconds: 400), () {
      _speakWelcomeMessage();
    });
  }

  Future<void> _speakWelcomeMessage() async {
    final ttsService = TextToSpeechService();
    String message = "Welcome back to Dementia Care";

    if (widget.lastMood != null && widget.lastMood!.isNotEmpty) {
      message += ". Your last logged mood was ${widget.lastMood}";
    }

    message += ". Have a wonderful day ahead.";

    await ttsService.speak(message);
  }

  Future<void> _dismissCard() async {
    await _animationController.reverse();
    setState(() {
      _isVisible = false;
    });

    // Mark as shown today
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('welcome_card_last_shown', today);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Welcome Back!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _dismissCard,
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.lastMood != null && widget.lastMood!.isNotEmpty
                          ? 'Your last logged mood was "${widget.lastMood}". Have a wonderful day ahead!'
                          : 'Ready to track your mood today? Have a wonderful day ahead!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Utility function to check if welcome card should be shown
Future<bool> shouldShowWelcomeCard() async {
  final prefs = await SharedPreferences.getInstance();
  final lastShown = prefs.getString('welcome_card_last_shown');
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  return lastShown != today;
}