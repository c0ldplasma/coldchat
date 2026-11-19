import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The app's binding. It differs from [WidgetsFlutterBinding] only in how animated images are timed.
///
/// Many GIFs, among them a few percent of BetterTTV's animated emotes, store a frame delay of 0 or 10 ms.
/// Browsers have long shown such frames for 100 ms instead, and the emotes were made to look right there.
/// Flutter plays the stored delay as is, so those emotes ran ten times too fast or more. Every image Flutter
/// decodes goes through [instantiateImageCodecWithSize], so this is the one place to apply the browsers' rule.
class ColdChatBinding extends WidgetsFlutterBinding {
  static bool _initialized = false;

  /// Call first thing in `main`, before anything else creates a binding. Unlike [WidgetsFlutterBinding], it
  /// can't ask whether a binding exists already: [WidgetsBinding.instance] throws until one does.
  static WidgetsBinding ensureInitialized() {
    if (!_initialized) {
      _initialized = true;
      ColdChatBinding();
    }
    return WidgetsBinding.instance;
  }

  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) async {
    final codec = await super.instantiateImageCodecWithSize(buffer, getTargetSize: getTargetSize);
    return codec.frameCount > 1 ? BrowserTimedCodec(codec) : codec;
  }
}

/// Shows frames that ask for 10 ms or less for [substitute] instead, as Chrome, Firefox and Safari do.
class BrowserTimedCodec implements ui.Codec {
  static const Duration threshold = Duration(milliseconds: 10);
  static const Duration substitute = Duration(milliseconds: 100);

  final ui.Codec _codec;

  BrowserTimedCodec(this._codec);

  @override
  int get frameCount => _codec.frameCount;

  @override
  int get repetitionCount => _codec.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final frame = await _codec.getNextFrame();
    return frame.duration > threshold ? frame : _RetimedFrame(frame.image, substitute);
  }

  @override
  void dispose() => _codec.dispose();
}

class _RetimedFrame implements ui.FrameInfo {
  @override
  final ui.Image image;

  @override
  final Duration duration;

  _RetimedFrame(this.image, this.duration);
}
