import 'package:flutter/material.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// STUNNING BACKGROUND RADIAL GRADIENTS ORBS ANIMATOR
// ---------------------------------------------------------------------------
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.midnightBg,
          ),
          child: Stack(
            children: [
              // Purple Orb (top left to center right)
              Positioned(
                top: -100 + (val * 200),
                left: -100 + (val * 150),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonPurple.withOpacity(0.2),
                        AppColors.neonPurple.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Teal Orb (bottom right to center left)
              Positioned(
                bottom: -150 + (val * 250),
                right: -100 + (val * 200),
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonTeal.withOpacity(0.18),
                        AppColors.neonTeal.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Pink Orb (middle-bottom animation)
              Positioned(
                top: 300 + (val * 100),
                right: 200 - (val * 300),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonPink.withOpacity(0.12),
                        AppColors.neonPink.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
