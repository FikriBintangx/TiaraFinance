import 'package:flutter/material.dart';

/// Reusable Animated Wavy Header Widget
/// Digunakan untuk semua screen agar konsisten
class AnimatedWavyHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Animation<double>? waveAnimation;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final Widget? subtitle;

  const AnimatedWavyHeader({
    super.key,
    required this.title,
    this.actions,
    this.waveAnimation,
    this.backgroundColor = const Color(0xFF6366F1),
    this.textColor = Colors.white,
    this.height = 180,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return ClipPath(
          clipper: _WavyHeaderClipper(
            animationValue: waveAnimation?.value ?? 0.0,
          ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Bar Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      subtitle!,
                    ],
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

/// Clipper untuk Wavy Header dengan animasi
class _WavyHeaderClipper extends CustomClipper<Path> {
  final double animationValue;

  _WavyHeaderClipper({this.animationValue = 0.0});

  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    // Add wave animation effect
    final waveOffset = animationValue * 20; // Max 20px wave movement
    
    var firstControlPoint = Offset(
      size.width / 4, 
      size.height + waveOffset
    );
    var firstEndPoint = Offset(
      size.width / 2.25, 
      size.height - 30 - waveOffset
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 3.25), 
      size.height - 80 + waveOffset
    );
    var secondEndPoint = Offset(
      size.width, 
      size.height - 40 - waveOffset
    );

    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy,
      firstEndPoint.dx, 
      firstEndPoint.dy
    );
    path.quadraticBezierTo(
      secondControlPoint.dx, 
      secondControlPoint.dy,
      secondEndPoint.dx, 
      secondEndPoint.dy
    );

    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WavyHeaderClipper oldClipper) => 
      oldClipper.animationValue != animationValue;
}

/// Simple Wavy Header tanpa back button (untuk screen dalam bottom nav)
class SimpleWavyHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Animation<double>? waveAnimation;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final Widget? subtitle;

  const SimpleWavyHeader({
    super.key,
    required this.title,
    this.actions,
    this.waveAnimation,
    this.backgroundColor = const Color(0xFF6366F1),
    this.textColor = Colors.white,
    this.height = 180,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return ClipPath(
          clipper: _WavyHeaderClipper(
            animationValue: waveAnimation?.value ?? 0.0,
          ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row with Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      subtitle!,
                    ],
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
