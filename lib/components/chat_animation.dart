import 'package:flutter/material.dart';

class ChatAnimationWidget extends StatefulWidget {
  const ChatAnimationWidget({super.key});

  @override
  State<ChatAnimationWidget> createState() => _ChatAnimationWidgetState();
}

class _ChatAnimationWidgetState extends State<ChatAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 13));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get t => _controller.value * 13.0;

  double calcOpacity(double startFadeIn, double endFadeIn, double startFadeOut, double endFadeOut) {
    if (t < startFadeIn || t > endFadeOut) return 0.0;
    if (t >= startFadeIn && t <= endFadeIn) {
      return (t - startFadeIn) / (endFadeIn - startFadeIn);
    }
    if (t >= startFadeOut && t <= endFadeOut) {
      return 1.0 - ((t - startFadeOut) / (endFadeOut - startFadeOut));
    }
    return 1.0;
  }

  double calcScale(double start, double end, {double minScale = 0.0, double maxScale = 1.0, bool elastic = false}) {
    if (t < start) return minScale;
    if (t >= end) return maxScale;

    double progress = (t - start) / (end - start);
    double curveValue = elastic ? Curves.elasticOut.transform(progress) : Curves.easeOutBack.transform(progress);

    return minScale + (maxScale - minScale) * curveValue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: 220,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {

          double leftAvatarOp = calcOpacity(0.0, 0.4, 2.5, 2.9);
          double leftBubbleOp = calcOpacity(0.2, 0.6, 2.5, 2.9);
          double leftBubbleScale = calcScale(0.2, 0.6);

          double rightAvatarOp = calcOpacity(1.2, 1.6, 2.5, 2.9);
          double rightBubbleOp = calcOpacity(1.4, 1.8, 2.5, 2.9);
          double rightBubbleScale = calcScale(1.4, 1.8);

          double pulseOp = calcOpacity(3.0, 3.5, 12.5, 13.0);
          double pulseScale = calcScale(3.0, 3.6, minScale: 0.3, maxScale: 1.0, elastic: true);

          return Stack(
            alignment: Alignment.center,
            children: [

              if (leftAvatarOp > 0 || leftBubbleOp > 0)
                Positioned(
                  left: 10,
                  bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Opacity(
                        opacity: leftAvatarOp.clamp(0.0, 1.0),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: leftBubbleOp.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: leftBubbleScale,
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Selam! 👋',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (rightAvatarOp > 0 || rightBubbleOp > 0)
                Positioned(
                  right: 10,
                  top: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: rightBubbleOp.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: rightBubbleScale,
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Pulse harika! 🚀',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Opacity(
                        opacity: rightAvatarOp.clamp(0.0, 1.0),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          child: Icon(Icons.person_3, size: 20, color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ),

              if (pulseOp > 0)
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Opacity(
                        opacity: pulseOp.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: pulseScale,
                          child: Text(
                            'Pulse',
                            style: TextStyle(
                              fontFamily: 'cursive',
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                                  offset: const Offset(3, 3),
                                  blurRadius: 5,
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(-2, -2),
                                  blurRadius: 5,
                                )
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
