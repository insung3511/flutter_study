import 'package:flutter/material.dart';

class DrawerAnimation extends StatefulWidget {
  final Widget child;
  final bool isOpen;

  const DrawerAnimation({
    Key? key,
    required this.child,
    required this.isOpen,
  }) : super(key: key);

  @override
  _DrawerAnimationState createState() => _DrawerAnimationState();
}

class _DrawerAnimationState extends State<DrawerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(DrawerAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 800),
          child: widget.child,
        );
      },
    );
  }
}
