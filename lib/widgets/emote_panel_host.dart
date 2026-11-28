import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/modal.dart';
import '../data/home/emote_panel_cubit.dart';
import '../sheets/emote.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/can_send.dart';
import '../tmi/channel/channel.dart';
import '../tmi/whispers/whisper_channel.dart';
import 'channel_switcher.dart';
import 'chat/emote_picker.dart';
import 'emote_button_icon_view.dart';

/// Shows the emote panel in the keyboard's place, below [child] (the home page's Scaffold), and moves [child] out of
/// its way the way the keyboard does: the panel's height is added to the keyboard inset the Scaffold avoids, so the
/// composer sits on whichever of the two is higher.
///
/// The panel is as tall as the keyboard was, so switching between them doesn't move the composer, like the emoji
/// keyboard in Messages: it appears behind the keyboard, which then slides away over it, and stays when the keyboard
/// comes back until the keyboard covers it. Without the keyboard up it slides in and out on its own.
///
/// Searching the panel needs the keyboard too: then the panel grows with it, so its search field and the first
/// results stay above the keyboard (like searching emoji on iOS), and shrinks back when the keyboard goes.
class EmotePanelHost extends StatefulWidget {
  final Widget child;

  /// The chat the panel's emotes go to: the one shown, or null on the home tab.
  final Channel? Function() channel;

  /// The keyboard's height as saved from an earlier start, so the panel fits before the keyboard was seen.
  final double? savedKeyboardHeight;

  /// Called with the keyboard's height when it settled at a new one, to save it.
  final void Function(double height)? onKeyboardHeight;

  const EmotePanelHost({
    super.key,
    required this.child,
    required this.channel,
    this.savedKeyboardHeight,
    this.onKeyboardHeight,
  });

  @override
  State<EmotePanelHost> createState() => _EmotePanelHostState();
}

class _EmotePanelHostState extends State<EmotePanelHost> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// The keyboard's height, as last seen open; the panel takes the same.
  late double _keyboardHeight = widget.savedKeyboardHeight ?? 0.0;

  /// Fires once the keyboard inset stopped changing: the keyboard is open, or gone.
  Timer? _settleTimer;

  /// The panel was closed for the keyboard, and stays until the keyboard covers it.
  bool _waitingForKeyboard = false;
  Timer? _keyboardTimeout;

  /// The mode the panel was last open in, kept while it slides away.
  EmotePanel _shownMode = EmotePanel.open;

  /// The panel's search field, which takes the keyboard.
  final FocusNode _searchFocus = FocusNode();

  /// Whether the panel is laid out for its search: while the search field has the keyboard, and after it lost it
  /// until the keyboard is down, so the panel shrinks back with the keyboard instead of jumping.
  bool _searchLayout = false;

  /// How much of the panel stays above the keyboard while searching: the search field, a section header and the
  /// first row of results, with a bit of the second to show there are more.
  static const double _aboveKeyboardWhileSearching = 176.0;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() => setState(() {
    _searchLayout = _searchFocus.hasFocus || (_searchLayout && MediaQuery.viewInsetsOf(context).bottom > 0.0);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (_waitingForKeyboard && inset >= _panelHeight - 1.0) _dropPanel();
    if (inset <= 0.0 && !_searchFocus.hasFocus) _searchLayout = false;
    // The inset changes on every frame of the keyboard's animation; once it holds still, the keyboard has settled.
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 120), _onKeyboardSettled);
  }

  void _onKeyboardSettled() {
    if (!mounted) return;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset <= 0.0) return;
    if (_waitingForKeyboard) {
      // The keyboard came up shorter than the panel, which was guessed or saved for another keyboard: let the panel
      // slide away now (the composer comes down the difference with it) and take the keyboard's height after.
      _waitingForKeyboard = false;
      _keyboardTimeout?.cancel();
      unawaited(_reveal.reverse().then((_) => _learnKeyboardHeight(inset)));
    } else if (_reveal.value == 0.0 || _searchFocus.hasFocus) {
      // Not while the panel shows without its search: its height would change under the composer.
      _learnKeyboardHeight(inset);
    }
  }

  void _learnKeyboardHeight(double height) {
    if (!mounted || (height - _keyboardHeight).abs() < 1.0) return;
    setState(() => _keyboardHeight = height);
    widget.onKeyboardHeight?.call(height);
  }

  double get _panelHeight {
    if (_keyboardHeight > 0.0) return _keyboardHeight;
    // Before the keyboard was ever seen: about a phone keyboard's height.
    final media = MediaQuery.of(context);
    return math.max(300.0, media.size.height * 0.38) + media.viewPadding.bottom;
  }

  void _onPanelChanged(BuildContext context, EmotePanel panel) {
    _keyboardTimeout?.cancel();
    if (panel == EmotePanel.closed) _searchLayout = _searchFocus.hasFocus;
    if (panel != EmotePanel.closed) {
      _shownMode = panel;
      _waitingForKeyboard = false;
      // Behind the keyboard, the panel is just there; the keyboard sliding away reveals it. It takes the keyboard's
      // height of this very moment, whatever was learned before, so the composer doesn't move.
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      if (keyboard > 0.0) {
        if (!_searchFocus.hasFocus) _learnKeyboardHeight(keyboard);
        _reveal.value = 1.0;
      } else {
        unawaited(_reveal.forward());
      }
    } else if (context.read<EmotePanelCubit>().keyboardNext) {
      _waitingForKeyboard = true;
      // A hardware keyboard never comes up.
      _keyboardTimeout = Timer(const Duration(milliseconds: 600), () {
        if (mounted && _waitingForKeyboard) {
          _waitingForKeyboard = false;
          unawaited(_reveal.reverse());
        }
      });
    } else {
      _waitingForKeyboard = false;
      unawaited(_reveal.reverse());
    }
    // A closed panel's search has nothing to type into; its keyboard goes along.
    if (panel == EmotePanel.closed && _searchFocus.hasFocus && !context.read<EmotePanelCubit>().keyboardNext) {
      _searchFocus.unfocus();
    }
  }

  // The keyboard covers the panel now; it can go without moving anything.
  void _dropPanel() {
    _waitingForKeyboard = false;
    _keyboardTimeout?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal.value = 0.0;
    });
  }

  @override
  void dispose() {
    _keyboardTimeout?.cancel();
    _settleTimer?.cancel();
    _searchFocus.dispose();
    _curve.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final searching = _searchLayout;
    // How far up from the screen's bottom the panel reaches. While searching, at least enough above the keyboard for
    // the search field and the first results; with the keyboard down that's no taller than usual.
    final panelTop = searching ? math.max(_panelHeight, keyboard + _aboveKeyboardWhileSearching) : _panelHeight;
    // While searching, its content ends at the keyboard, so the results scroll all the way up into view. Its sheet
    // still reaches the screen's bottom: iOS's keyboard has rounded top corners, and the sheet shows through them
    // instead of the chat. Otherwise the content keeps clear of the home indicator, and the keyboard covers the
    // panel while handing over.
    // Without a search the emotes reach the bottom edge, scrolling on below the section bar floating where the
    // channel switcher's capsule sits.
    // After the search let go of the keyboard, the content follows the keyboard alone down to 0, so the section bar
    // that is back rides down on it all the way instead of stopping above the home indicator.
    final contentBottom = !searching
        ? 0.0
        : _searchFocus.hasFocus
        ? math.max(keyboard, media.viewPadding.bottom)
        : keyboard;
    final sectionBarInset = ChannelSwitcher.bottomInset(context);
    return BlocListener<EmotePanelCubit, EmotePanel>(
      listener: _onPanelChanged,
      child: BlocSelector<EmotePanelCubit, EmotePanel, bool>(
        selector: (panel) => panel != EmotePanel.closed,
        // Android's back gesture closes the panel first, like it closes the keyboard.
        builder: (context, open) => PopScope(
          canPop: !open,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<EmotePanelCubit>().hide();
          },
          child: AnimatedBuilder(
            animation: _curve,
            child: widget.child,
            builder: (context, child) {
              final shown = panelTop * _curve.value;
              final channel = widget.channel();
              // iOS's keyboard is translucent: the panel's emotes fade as it covers them and come back as it leaves,
              // instead of popping in or out behind it. While searching, the keyboard is the panel's own.
              final contentOpacity = searching ? 1.0 : (1.0 - keyboard / panelTop).clamp(0.0, 1.0);
              // Its sheet turns into the chat's color the same way, so that's what is behind the keyboard when the
              // panel goes, as with the keyboard alone.
              final chatColor = Theme.of(context).colorScheme.surface;
              final panelVisible = _reveal.value > 0.0 && channel != null;
              final sheetColor = Color.lerp(chatColor, ChatColors.of(context).sheet, contentOpacity)!;
              return Stack(
                children: [
                  MediaQuery(
                    data: media.copyWith(
                      viewInsets: media.viewInsets.copyWith(bottom: math.max(media.viewInsets.bottom, shown)),
                    ),
                    child: child!,
                  ),
                  // Behind the translucent keyboard and its rounded corners: the chat's color, or the panel's sheet
                  // while the panel is there, rather than the channel switcher shining through. Always in the Stack
                  // (zero high without a keyboard): appearing in front of the panel would make Flutter rebuild the
                  // panel, dropping its search field's focus and with it the keyboard that just started to open.
                  Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: 0.0,
                    height: keyboard,
                    child: ColoredBox(color: panelVisible ? sheetColor : chatColor),
                  ),
                  if (panelVisible)
                    Positioned(
                      left: 0.0,
                      right: 0.0,
                      bottom: shown - panelTop,
                      height: panelTop,
                      child: _Panel(
                        channel: channel,
                        mode: _shownMode,
                        searchFocus: _searchFocus,
                        bottomPadding: contentBottom,
                        sectionBarInset: sectionBarInset,
                        contentOpacity: contentOpacity,
                        color: sheetColor,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The emote picker on an opaque, keyboard-like sheet, clear of the home indicator.
class _Panel extends StatelessWidget {
  final Channel channel;
  final EmotePanel mode;
  final FocusNode searchFocus;
  final double bottomPadding;

  /// How far the section bar floats above the screen's bottom edge.
  final double sectionBarInset;

  /// Of the emotes only; the sheet behind them stays opaque.
  final double contentOpacity;

  /// The sheet's color: [ChatColors.sheet], or on the way to the chat's color while the keyboard covers the panel.
  final Color color;

  const _Panel({
    required this.channel,
    required this.mode,
    required this.searchFocus,
    required this.bottomPadding,
    required this.sectionBarInset,
    required this.contentOpacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ChatColors.of(context);
    final needsLogin = composerNeedsLogin(channel.sendAvailability, isWhisper: channel is WhisperChannel);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
            side: BorderSide(color: colors.glassBorder, width: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Opacity(
            opacity: contentOpacity,
            child: EmotePicker(
              client: channel.client,
              channel: channel,
              backgroundColor: color,
              searchFocusNode: searchFocus,
              bottomInset: sectionBarInset,
              // Without a text field to put it in, an emote shows what it is instead.
              onShowEmote: needsLogin
                  ? (emote) => Modal.show(
                      context: context,
                      child: EmoteModal(emote: emote),
                    )
                  : null,
              onPickButtonIcon: mode == EmotePanel.pickingButtonIcon
                  ? (emote) async {
                      final panel = context.read<EmotePanelCubit>();
                      if (await chooseEmoteButtonIcon(context, emote)) panel.hide();
                    }
                  : null,
              getFieldInput: () => channel.composerDraft.text,
              setFieldInput: (_) {},
              insertFieldInput: channel.composerDraft.insert,
            ),
          ),
        ),
      ),
    );
  }
}
