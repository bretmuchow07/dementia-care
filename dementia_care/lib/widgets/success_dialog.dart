import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dementia_care/services/tts_service.dart';

class SuccessDialog extends StatefulWidget {
  final String moodName;
  final String? emoji;
  final int? streakCount;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.moodName,
    this.emoji,
    this.streakCount,
    this.onDismiss,
  });

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _ttsPlayed = false;

  final TextToSpeechService _ttsService = TextToSpeechService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _dismiss();
      }
    });

    // Play TTS after animation starts
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_ttsPlayed) {
        _playSuccessTTS();
      }
    });
  }

  Future<void> _playSuccessTTS() async {
    if (_ttsPlayed) return;

    _ttsPlayed = true;

    final affirmation = _getMoodAffirmation(widget.moodName);
    final message = "Mood logged successfully! $affirmation";

    try {
      await _ttsService.speak(message);
    } catch (e) {
      // Silently handle TTS errors
      debugPrint('TTS failed: $e');
    }
  }

  String _getMoodAffirmation(String mood) {
    final affirmations = {
      'Happy': "You're feeling happy today, that's wonderful! Keep that positive energy flowing.",
      'Sad': "It's okay to feel sad sometimes. Remember that brighter days are ahead.",
      'Anxious': "It's okay to feel anxious, take a deep breath. You're doing your best.",
      'Calm': "You're feeling calm and centered. That's a beautiful state of mind.",
      'Excited': "Your excitement is contagious! Enjoy this moment of joy.",
      'Angry': "It's normal to feel angry. Take a moment to breathe and process your feelings.",
      'Tired': "You're feeling tired, that's okay. Rest is important for your well-being.",
      'Content': "Feeling content is a wonderful place to be. Cherish this peaceful moment.",
      'Frustrated': "Frustration is temporary. You're capable of overcoming this challenge.",
      'Peaceful': "Peaceful moments like this are precious. Enjoy the tranquility.",
      'Neutral': "Every mood has its place. You're exactly where you need to be right now.",
    };

    return affirmations[mood.toLowerCase()] ?? affirmations['Neutral']!;
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lottie Animation
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Lottie.asset(
                        'assets/animations/success.json', // You'll need to add this asset
                        fit: BoxFit.contain,
                        repeat: false,
                        onLoaded: (composition) {
                          // Animation will play once
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Success message
                    Text(
                      'Mood Logged Successfully!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Mood display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.emoji != null)
                          Text(
                            widget.emoji!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          widget.moodName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getMoodColor(widget.moodName),
                          ),
                        ),
                      ],
                    ),

                    // Streak info
                    if (widget.streakCount != null && widget.streakCount! > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '🔥 ${widget.streakCount} day streak!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Manual close button
                    TextButton(
                      onPressed: _dismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getMoodColor(String mood) {
    final colors = {
      'Happy': const Color(0xFFFFD700),
      'Sad': const Color(0xFF4169E1),
      'Anxious': const Color(0xFFFF6347),
      'Calm': const Color(0xFF32CD32),
      'Excited': const Color(0xFFFF69B4),
      'Angry': const Color(0xFFDC143C),
      'Tired': const Color(0xFF808080),
      'Content': const Color(0xFF00CED1),
      'Frustrated': const Color(0xFFFF4500),
      'Peaceful': const Color(0xFF98FB98),
    };

    return colors[mood.toLowerCase()] ?? Colors.grey;
  }

  static void show(
    BuildContext context, {
    required String moodName,
    String? emoji,
    int? streakCount,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        moodName: moodName,
        emoji: emoji,
        streakCount: streakCount,
        onDismiss: onDismiss,
      ),
    );
  }
}