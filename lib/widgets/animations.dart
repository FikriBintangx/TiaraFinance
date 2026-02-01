import 'package:flutter/material.dart';

// 1. Fade In & Slide Animation
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset; // Vertical offset

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 0),
    this.offset = 30.0,
  });

  const FadeInSlide.delayed({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    required this.delay,
    this.offset = 30.0,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween<Offset>(begin: Offset(0, widget.offset / 100), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}


// 2. Scale Button (Micro-interaction)
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final Duration duration;

  const ScaleButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: widget.child,
      ),
    );
  }
}

// 3. Staggered List Animation Wrapper
class StaggeredList extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double offset;

  const StaggeredList({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 375),
    this.offset = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInSlide.delayed(
      duration: duration,
      delay: Duration(milliseconds: index * 50),
      offset: offset,
      child: child,
    );
  }
}
