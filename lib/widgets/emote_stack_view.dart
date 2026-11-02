import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/emote.dart';

/// Draws an [EmoteStack]: the overlays centered on top of the base emote, then the FrankerFaceZ effects applied
/// to the whole stack. [image] builds a single emote the way chat draws it.
class EmoteStackView extends StatelessWidget {
  final EmoteStack stack;
  final Widget Function(Emote emote) image;

  const EmoteStackView({super.key, required this.stack, required this.image});

  // Rec. 709 luminance for greyscale, and the common sepia matrix.
  static const List<double> _greyscale = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];
  static const List<double> _sepia = [
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    Widget child = stack.overlays.isEmpty
        ? image(stack.base)
        : Stack(
            alignment: Alignment.center,
            children: [
              image(stack.base),
              for (final overlay in stack.overlays) image(overlay),
            ],
          );

    final effects = stack.effects;
    if (effects & EmoteFlags.growX != 0) child = _StretchX(child: child);
    if (effects & (EmoteFlags.flipX | EmoteFlags.flipY) != 0) {
      child = Transform.flip(flipX: effects & EmoteFlags.flipX != 0, flipY: effects & EmoteFlags.flipY != 0, child: child);
    }
    if (effects & EmoteFlags.rotate90 != 0) child = RotatedBox(quarterTurns: 1, child: child);
    if (effects & EmoteFlags.greyscale != 0) child = ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: child);
    if (effects & EmoteFlags.sepia != 0) child = ColorFiltered(colorFilter: const ColorFilter.matrix(_sepia), child: child);
    return child;
  }
}

/// Twice as wide as its child, which is stretched to fill it (FrankerFaceZ's ffzW).
class _StretchX extends SingleChildRenderObjectWidget {
  const _StretchX({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderStretchX();
}

class _RenderStretchX extends RenderProxyBox {
  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(BoxConstraints(maxWidth: constraints.maxWidth / 2, maxHeight: constraints.maxHeight), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width * 2, child.size.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.pushTransform(needsCompositing, offset, Matrix4.diagonal3Values(2.0, 1.0, 1.0), (context, offset) => super.paint(context, offset));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      super.hitTestChildren(result, position: Offset(position.dx / 2, position.dy));

  @override
  double computeMinIntrinsicWidth(double height) => super.computeMinIntrinsicWidth(height) * 2;

  @override
  double computeMaxIntrinsicWidth(double height) => super.computeMaxIntrinsicWidth(height) * 2;
}
