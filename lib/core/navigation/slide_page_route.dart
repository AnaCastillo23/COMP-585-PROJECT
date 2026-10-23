import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required WidgetBuilder builder})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) {
          return builder(context);
        },
        opaque: false,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 340),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      );
}

class SlideFormPanel extends StatelessWidget {
  const SlideFormPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final routeAnimation = ModalRoute.of(context)?.animation;

    if (routeAnimation == null) return child;

    final curvedAnimation = CurvedAnimation(
      parent: routeAnimation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: ColoredBox(color: Colors.white, child: child),
      ),
    );
  }
}
