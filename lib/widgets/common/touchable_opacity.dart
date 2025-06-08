import 'package:flutter/material.dart';

class TouchableOpacity extends StatefulWidget {
  final Widget child;
  final Function onTap;
  final Duration duration;
  final double opacity;

  const TouchableOpacity({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 50),
    this.opacity = 0.5,
  });

  @override
  State<TouchableOpacity> createState() => _TouchableOpacityState();
}

class _TouchableOpacityState extends State<TouchableOpacity> {
  bool isDown = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => isDown = true),
        onTapUp: (_) => setState(() => isDown = false),
        onTapCancel: () => setState(() => isDown = false),
        onTap: () => widget.onTap(),
        child: AnimatedOpacity(
          duration: widget.duration,
          opacity: isDown ? widget.opacity : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
