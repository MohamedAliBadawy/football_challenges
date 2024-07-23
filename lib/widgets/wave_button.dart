import 'package:flutter/material.dart';

class PrettyWaveButton extends StatefulWidget {
  const PrettyWaveButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 50.0,
    this.backgroundColor = Colors.green,
    this.verticalPadding = 14.0,
    this.horizontalPadding = 15.0,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeInOut,
    this.waveLength = 6.0,
  });
  final VoidCallback onPressed;
  final double borderRadius;
  final Color backgroundColor;
  final double verticalPadding;
  final double horizontalPadding;
  final Duration duration;
  final Curve curve;
  final double waveLength;
  final Widget child;
  @override
  State<PrettyWaveButton> createState() => _PrettyWaveButtonState();
}

class _PrettyWaveButtonState extends State<PrettyWaveButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener(controllerListener);
    _controller.forward();
  }

  void controllerListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTapDown: (_) {
          _controller.reset();
          widget.onPressed();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBorderButton(
              animation: _controller,
              curve: widget.curve,
              verticalPadding: widget.verticalPadding,
              horizontalPadding: widget.horizontalPadding,
              waveLength: widget.waveLength,
              backgroundColor: widget.backgroundColor,
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius + 2),
                color: widget.backgroundColor,
              ),
              padding: EdgeInsets.symmetric(
                vertical: widget.verticalPadding,
                horizontal: widget.horizontalPadding,
              ),
              margin: EdgeInsets.all(widget.waveLength),
              child: widget.child,
            ),
          ],
        ));
  }
}

class AnimatedBorderButton extends AnimatedWidget {
  const AnimatedBorderButton({
    super.key,
    required this.animation,
    required this.curve,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.borderRadius,
    required this.waveLength,
    required this.backgroundColor,
    required this.child,
  }) : super(
          listenable: animation,
        );
  final Animation<double> animation;
  final Curve curve;
  final double verticalPadding;
  final double horizontalPadding;
  final double borderRadius;
  final double waveLength;
  final Color backgroundColor;
  final Widget child;

  Animation<double> get verticalBorderAnimation => Tween<double>(
        begin: verticalPadding - waveLength,
        end: verticalPadding + waveLength,
      ).animate(curvedAnimation);

  Animation<double> get horizontalBorderAnimation => Tween<double>(
        begin: horizontalPadding - waveLength,
        end: horizontalPadding + waveLength,
      ).animate(curvedAnimation);

  Animation<double> get borderAnimation =>
      Tween<double>(begin: waveLength, end: 0.0).animate(curvedAnimation);

  Animation<double> get curvedAnimation => CurvedAnimation(
        parent: animation,
        curve: curve,
      );
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: backgroundColor,
          width: borderAnimation.value,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: Colors.transparent,
      ),
      padding: EdgeInsets.symmetric(
        vertical: verticalBorderAnimation.value,
        horizontal: horizontalBorderAnimation.value,
      ),
      child: child,
    );
  }
}
