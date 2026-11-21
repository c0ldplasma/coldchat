import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out [child] unchanged and calls [onSize] after the frame whenever the child's size changed, including the
/// first layout. Layouts that keep the size don't call back, so rebuilding with the reported size can't loop.
class SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;

  const SizeReporter({super.key, required this.onSize, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class RenderSizeReporter extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _reported;

  RenderSizeReporter(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    // Widgets can't be rebuilt during layout; report once this frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(size);
    });
  }
}
