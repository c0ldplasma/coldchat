import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/glass.dart';
import '../components/modal.dart';
import '../components/pressable.dart';
import '../components/size_reporter.dart';
import '../components/tile.dart';
import '../data/emote_cache.dart';
import '../data/filesharing/upload_queue_cubit.dart';
import '../data/filesharing/upload_task.dart';
import '../data/home/emote_panel_cubit.dart';
import '../data/repositories/custom_command_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../sheets/login.dart';
import '../sheets/whisper_errors.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/can_send.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/composer_draft.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../tools/browser_warmup.dart';
import '../tools/composer/composer_send.dart';
import '../tools/composer/composer_text.dart';
import '../tools/emotes/autocompletion_matcher.dart';
import '../tools/emotes/visible_emotes.dart';
import 'chat/upload_queue_bar.dart';
import 'chat_view.dart';
import 'emoji_glyph.dart';
import 'emote_button_icon_view.dart';

class ChannelView extends StatefulWidget {
  final Channel channel;

  const ChannelView({
    super.key,
    required this.channel,
  });

  @override
  State<ChannelView> createState() => ChannelViewState();
}

class AutocompletionItem {
  final Widget? prefix;
  final String title;
  final String? subtitle;
  final void Function()? onTap;
  final void Function()? onLongPress;

  AutocompletionItem({
    this.prefix,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
  });
}

class ChannelViewState extends State<ChannelView> {
  final FocusNode textFocusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  // Keeps the autocompletion's emote and chatter lists between rebuilds, see [AutocompletionMatcher].
  final AutocompletionMatcher _autocompletion = AutocompletionMatcher();
  // Each emote list without the emotes of sections hidden in the emote picker.
  final VisibleEmotes _visibleChannelEmotes = VisibleEmotes();
  final VisibleEmotes _visibleGlobalEmotes = VisibleEmotes();
  final VisibleEmotes _visibleUserEmotes = VisibleEmotes();
  StreamSubscription<UploadTask>? _uploadSubscription;
  StreamSubscription<String>? _mentionSubscription;
  StreamSubscription<String>? _insertionSubscription;

  /// Height of everything floating over the bottom of the chat (cards, composer, emote panel, channel switcher), so
  /// the newest message can scroll up above it.
  double _dockHeight = 0.0;

  /// The chat behind the composer, created once per [_dockHeight]. The composer calls setState on every keystroke;
  /// handing Flutter the same widget again makes it skip the chat instead of rebuilding the list and every visible
  /// message.
  Widget? _chat;
  double? _chatInset;

  Widget _chatWithInset(double bottom) {
    if (_chat == null || _chatInset != bottom) {
      _chatInset = bottom;
      _chat = _ChannelChat(channel: widget.channel, bottomInset: bottom);
    }
    return _chat!;
  }

  @override
  void didUpdateWidget(ChannelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel != oldWidget.channel) _chat = null;
  }

  // The keyboard and the emote panel take turns: tapping into the field brings the keyboard back and the panel goes.
  void _onFocusChange() {
    if (textFocusNode.hasFocus) context.read<EmotePanelCubit>().hide(keyboardNext: true);
  }

  /// The emote button: swaps the keyboard for the panel, or the panel back for the keyboard.
  void _toggleEmotePanel({required bool hasField}) {
    final panel = context.read<EmotePanelCubit>();
    if (panel.isOpen) {
      panel.hide(keyboardNext: hasField);
      if (hasField) textFocusNode.requestFocus();
    } else {
      textFocusNode.unfocus();
      panel.toggle();
    }
  }

  void _pickEmoteButtonIcon() {
    textFocusNode.unfocus();
    context.read<EmotePanelCubit>().pickButtonIcon();
  }

  @override
  void initState() {
    super.initState();
    textFocusNode.addListener(_onFocusChange);
    // This view is disposed while its tab is off screen; pick up where the
    // composer was left.
    final draft = widget.channel.composerDraft;
    textEditingController.value = TextEditingValue(
      text: draft.text,
      selection: TextSelection.collapsed(offset: draft.restoredCaret),
    );
    // "Mention" in a message sheet while this view is shown.
    _mentionSubscription = draft.mentions.listen((word) {
      if (mounted) setState(() => textEditingController.value = appendWord(textEditingController.value, word));
    });
    // Emotes picked in the emote panel, which the home page shows in the keyboard's place.
    _insertionSubscription = draft.insertions.listen((word) {
      if (mounted) textEditingController.value = insertWord(textEditingController.value, word);
    });

    // Insert finished uploads into this channel's composer only; other tabs
    // ignore them. Uploads that finished while this view was gone wait in the
    // queue and are inserted now.
    final queue = context.read<UploadQueueCubit>();
    _uploadSubscription = queue.completed.listen((task) {
      if (!mounted || task.channelName != widget.channel.name) return;
      _insertUploadedUrls(queue.takeUploadedUrls(widget.channel.name));
      setState(() {});
    });
    _insertUploadedUrls(queue.takeUploadedUrls(widget.channel.name));
    if (Platform.isAndroid && !_lostPhotoChecked) {
      _lostPhotoChecked = true;
      unawaited(recoverLostPhoto());
    }
  }

  // Android may kill the app while the camera is in front. The photo is then
  // handed back on the next launch, once, so only the first view asks for it.
  static bool _lostPhotoChecked = false;

  Future<void> recoverLostPhoto() async {
    final queue = context.read<UploadQueueCubit>();
    final response = await ImagePicker().retrieveLostData();
    final photo = response.file;
    if (photo == null) return;
    unawaited(
      queue.uploadFile(
        path: photo.path,
        filename: photo.name,
        channelName: widget.channel.name,
      ),
    );
  }

  // A whisper conversation only exists while logged in and is sent over Helix, so it keeps its composer.
  bool _needsLogin(SendAvailability availability) =>
      composerNeedsLogin(availability, isWhisper: widget.channel is WhisperChannel);

  Future<void> sendMessage() async {
    // TODO: Implement reactions here

    final original = textEditingController.text;
    final customCommand = context.read<CustomCommandRepository>().commandFor(original.trim().split(' ').first);
    final text = customCommand?.expand(original) ?? original;

    final action = composerSendFor(
      text,
      isWhisperChannel: widget.channel is WhisperChannel,
      canSend: widget.channel.canSend,
    );
    final whispers = widget.channel.client.whispers;
    final Future<void> Function()? sendWhisper = switch (action) {
      OpenWhisper(:final login) => () => whispers.openAndFocus(login),
      SendWhisper(:final login, :final message) => () => whispers.sendTo(login, message),
      SendInWhisperChannel() => () => widget.channel.send(text),
      SendToChannel() || NotConnected() => null,
    };
    final draft = widget.channel.composerDraft;
    if (sendWhisper != null) {
      draft.replyTo(null);
      textEditingController.clear();
      unawaited(_sendWhisper(sendWhisper, original));
      return;
    }

    // Keep the message in the composer and say so instead of clearing it.
    if (action is NotConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).messageNotSentNotConnected)));
      return;
    }

    final reply = draft.state;
    unawaited(
      widget.channel.send(
        text,
        tags: {
          if (reply != null) 'reply-parent-msg-id': reply.id,
        },
      ),
    );

    draft.replyTo(null);

    textEditingController.clear();
  }

  /// Runs [send] and, if the whisper isn't sent, says why and puts [original] back into an empty composer.
  Future<void> _sendWhisper(Future<void> Function() send, String original) async {
    try {
      await send();
    } catch (e) {
      if (!mounted) return;
      if (textEditingController.text.isEmpty) {
        textEditingController.text = original;
        textEditingController.selection = TextSelection.collapsed(offset: original.length);
        setState(() {});
      }
      showWhisperError(ScaffoldMessenger.of(context), Navigator.of(context), e);
    }
  }

  /// Pick files and hand them to the global upload queue.
  ///
  /// Deliberately does not await the uploads: the composer stays usable, the
  /// progress chips above it report state, and each URL is inserted when it
  /// actually arrives. The old version awaited every upload inline, snapshotted
  /// the text beforehand and wrote that snapshot back afterwards — which threw
  /// away anything typed in the meantime and showed nothing while it ran.
  Future<void> pickAndUploadFiles() async {
    // An upload only ends up as a link in a message, so without a login the choices are shown but can't be picked.
    final needsLogin = _needsLogin(widget.channel.sendAvailability);
    final channelContext = context;
    await Modal.show(
      context: context,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsLogin)
              WarmsUpTwitchLogin(
                child: Tile(
                  title: AppLocalizations.of(context).uploadNeedsLogin,
                  prefix: Icon(Icons.login_rounded, color: Theme.of(context).colorScheme.primary),
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(showTwitchLogin(channelContext));
                  },
                ),
              ),
            Opacity(
              opacity: needsLogin ? 0.4 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tile(
                    title: AppLocalizations.of(context).takePhoto,
                    prefix: const Icon(Icons.photo_camera_outlined),
                    onTap: needsLogin
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            unawaited(takeAndUploadPhoto());
                          },
                  ),
                  Tile(
                    title: AppLocalizations.of(context).chooseFromLibrary,
                    prefix: const Icon(Icons.photo_library_outlined),
                    onTap: needsLogin
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            unawaited(pickAndUploadFromLibrary());
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takeAndUploadPhoto() async {
    final queue = context.read<UploadQueueCubit>();
    final XFile? photo;
    try {
      // imageQuality makes the plugin re-encode to JPEG, so an iPhone's HEIC
      // capture arrives in a format every upload host and browser accepts.
      photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    } catch (e) {
      // Camera access denied or no camera on this device.
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).cameraUnavailable)));
      }
      return;
    }
    if (photo == null) return;

    unawaited(
      queue.uploadFile(
        path: photo.path,
        filename: photo.name,
        channelName: widget.channel.name,
      ),
    );
  }

  Future<void> pickAndUploadFromLibrary() async {
    final queue = context.read<UploadQueueCubit>();
    // Picks several files; an empty list means the user cancelled.
    final files = await FilePicker.pickFiles(
      type: Platform.isIOS ? FileType.image : FileType.any,
    );

    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      unawaited(
        queue.uploadFile(
          path: path,
          filename: file.name,
          channelName: widget.channel.name,
        ),
      );
    }
  }

  void _insertUploadedUrls(List<String> urls) {
    for (final url in urls) {
      _insertUploadedUrl(url);
    }
  }

  /// Drop [url] where the caret is, preserving whatever has been typed since
  /// the upload started, and leave the caret after it ready for more text.
  void _insertUploadedUrl(String url) {
    textEditingController.value = insertWord(textEditingController.value, url);
  }

  /// Puts [word] in place of the word being typed, for a tapped autocompletion.
  void _complete(String word) {
    textEditingController.value = completeLastWord(textEditingController.value, word);
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(_uploadSubscription?.cancel());
    unawaited(_mentionSubscription?.cancel());
    unawaited(_insertionSubscription?.cancel());
    final selection = textEditingController.selection;
    widget.channel.composerDraft.save(
      text: textEditingController.text,
      caret: selection.isValid ? selection.end : -1,
    );
    textEditingController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  List<AutocompletionItem> getAutocompletionItems() {
    if (textEditingController.text.split(' ').last.length < 2) return [];
    final typed = textEditingController.text.split(' ').last;
    final currentSearch = typed.toLowerCase();

    final chatSettings = context.read<SettingsRepository>().chatSettings;

    final hiddenSections = context.read<SettingsRepository>().hiddenEmoteSections.keys.toSet();
    final sortedEmotes = _autocompletion.emotes(
      channelEmotes: _visibleChannelEmotes.of(widget.channel.channelEmotes.state, hiddenSections),
      globalEmotes: _visibleGlobalEmotes.of(widget.channel.client.globals.emotes.state, hiddenSections),
      userEmotes: _visibleUserEmotes.of(widget.channel.client.globals.twitchUserEmotes.state, hiddenSections),
      // As typed: emote names are case-sensitive, so `Kappa` ranks above `kappa` for "Kappa".
      search: typed,
      needsColon: chatSettings.emoteAutocompletionWithColon,
    );
    final matchingChatters = _autocompletion.chatters(
      messages: widget.channel.channelMessages.state,
      search: currentSearch,
      needsAt: chatSettings.userAutocompletionWithAt,
    );

    return [
      for (final user in matchingChatters)
        AutocompletionItem(
          prefix: const Icon(Icons.person_outline_rounded),
          title: user.displayName ?? user.login!,
          subtitle: user.login,
          onTap: () => _complete('${user.login}'),
        ),
      for (final customCommand in context.read<CustomCommandRepository>().commandsStartingWith(
        textEditingController.text,
      ))
        AutocompletionItem(
          prefix: const Icon(Icons.keyboard_command_key_rounded),
          title: customCommand.trigger,
          subtitle: customCommand.command,
          onTap: () => _complete(customCommand.trigger),
        ),
      for (final emote in sortedEmotes)
        AutocompletionItem(
          prefix: EmoteGlyph(
            emote: emote,
            size: 24.0,
            image: () => CachedNetworkImage(
              imageUrl: emote.mipmap.last,
              cacheManager: EmoteCacheManager.instance,
              width: 24.0,
              height: 24.0,
            ),
          ),
          title: emote.name,
          subtitle: emote.source.name,
          onTap: () => _complete(emote.code ?? emote.name),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // The channel switcher's height while it's shown (the page extends behind it), else the home indicator's.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: _chatWithInset(_dockHeight)),
        Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
          child: SizeReporter(
            onSize: (size) => setState(() => _dockHeight = size.height),
            child: BlocBuilder<EmotePanelCubit, EmotePanel>(
              builder: (context, panel) => _dock(context, panel, bottomInset),
            ),
          ),
        ),
      ],
    );
  }

  /// Everything floating over the bottom of the chat, on a fade that keeps it readable over the messages: the cards
  /// (hints, uploads, the reply, autocompletion) and the composer. The emote panel is the home page's
  /// ([EmotePanelHost]), in the keyboard's place.
  Widget _dock(BuildContext context, EmotePanel panel, double bottomInset) {
    final l10n = AppLocalizations.of(context);
    final channel = widget.channel;
    final panelOpen = panel != EmotePanel.closed;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
          ],
          stops: const [0.0, 0.6],
        ),
      ),
      child: Padding(
        // With the chat list's own 8 below its newest message, 10 points between the messages and the composer.
        padding: const EdgeInsets.only(top: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (channel is WhisperChannel) const _WhisperHistoryHint(),
            if (channel is WhisperChannel && !channel.client.whispers.hasScope)
              _DockCard(
                onTap: () => showTwitchLogin(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12.0),
                      Expanded(child: Text(l10n.whisperNeedsScope)),
                      const SizedBox(width: 8.0),
                      Text(
                        l10n.signInAgain,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            UploadQueueBar(channelName: channel.name),
            _ReplyCard(draft: channel.composerDraft),
            // Follows the text however it changes (typing, sending clears it, a completion or mention edits it), not
            // only the rebuilds typing causes: sending clears the field without one.
            ListenableBuilder(
              listenable: textEditingController,
              builder: (context, _) => _Suggestions(items: getAutocompletionItems()),
            ),
            Padding(
              // Above the channel switcher, or above the keyboard or the emote panel covering it: the Scaffold
              // lifts the page above whichever is higher and then reports no inset.
              padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, bottomInset + 8.0),
              // Logged out (or with a refused login) the text field becomes a login button: nothing could be sent.
              // Uploads and the emote panel stay, they say themselves what needs a login.
              child: BlocBuilder<CanSend, SendAvailability>(
                bloc: channel.canSendCubit,
                builder: (context, availability) => _composer(context, availability, panelOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(BuildContext context, SendAvailability availability, bool panelOpen) {
    final l10n = AppLocalizations.of(context);
    final needsLogin = _needsLogin(availability);
    final emoteButton = _EmoteButton(
      active: panelOpen,
      onTap: () => _toggleEmotePanel(hasField: !needsLogin),
      onLongPress: _pickEmoteButtonIcon,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _RoundGlassButton(
          onTap: pickAndUploadFiles,
          semanticLabel: l10n.attachPhoto,
          child: const Icon(Icons.add_rounded, size: 26.0),
        ),
        const SizedBox(width: 8.0),
        if (needsLogin) ...[
          const Expanded(child: _LoginToChatButton()),
          const SizedBox(width: 8.0),
          Glass(
            shape: const CircleBorder(),
            child: SizedBox.square(dimension: _composerHeightOf(context), child: emoteButton),
          ),
        ] else
          Expanded(
            child: _MessageField(
              controller: textEditingController,
              focusNode: textFocusNode,
              hintText: widget.channel is WhisperChannel
                  ? l10n.whisperTo((widget.channel as WhisperChannel).partnerDisplayName)
                  : availability == SendAvailability.ready
                  ? l10n.sendMessageIn(widget.channel.name)
                  : l10n.channelConnecting(widget.channel.name),
              ready: availability == SendAvailability.ready || widget.channel is WhisperChannel,
              emoteButton: emoteButton,
              onSend: () => unawaited(sendMessage()),
            ),
          ),
      ],
    );
  }
}

/// The message field's text: 16 points with a 20 point line, so one line plus the field's padding is exactly
/// [_composerHeightOf] tall.
const double _fieldFontSize = 16.0;
const double _fieldLineHeight = 1.25;
const double _fieldVerticalPadding = 12.0;

/// Height of the composer's one-line text field and of the round buttons beside it: Apple's minimum touch target of
/// 44 points, or more when the phone's text size makes a line taller, so the buttons always match the field.
double _composerHeightOf(BuildContext context) => math.max(
  44.0,
  MediaQuery.textScalerOf(context).scale(_fieldFontSize) * _fieldLineHeight + 2 * _fieldVerticalPadding,
);

/// A round glass button beside the text field.
class _RoundGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const _RoundGlassButton({required this.child, required this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: semanticLabel,
    child: Glass(
      shape: const CircleBorder(),
      child: SizedBox.square(dimension: _composerHeightOf(context), child: child),
    ),
  );
}

/// The emote panel's button: the chosen emote, or the smiley; tinted while the panel is open. A long press picks
/// the emote it shows.
class _EmoteButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EmoteButton({required this.active, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    onLongPress: onLongPress,
    semanticLabel: AppLocalizations.of(context).emoteMenu,
    child: SizedBox(
      width: 40.0,
      height: _composerHeightOf(context),
      child: Center(
        child: active
            ? Icon(Icons.keyboard_rounded, color: Theme.of(context).colorScheme.primary)
            : const EmoteButtonIconView(),
      ),
    ),
  );
}

/// The message field: a glass capsule that grows to five lines, with the emote button at its end and, once there is
/// text, the round send button, like Messages on iOS. The keyboard's return key sends too; a chat message has no line
/// breaks, long ones only wrap.
class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool ready;
  final Widget emoteButton;
  final VoidCallback onSend;

  const _MessageField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.ready,
    required this.emoteButton,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = _composerHeightOf(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(fontSize: _fieldFontSize, height: _fieldLineHeight);
    return Glass(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(height / 2))),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                style: textStyle,
                // The strut keeps a line 20 points tall whatever it holds (an emoji is taller than letters), so the
                // field stays as tall as the buttons beside it.
                strutStyle: const StrutStyle(
                  fontSize: _fieldFontSize,
                  height: _fieldLineHeight,
                  forceStrutHeight: true,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.fromLTRB(16.0, _fieldVerticalPadding, 4.0, _fieldVerticalPadding),
                  hintText: hintText,
                  hintMaxLines: 1,
                  hintStyle: textStyle?.copyWith(color: ChatColors.of(context).muted),
                  border: InputBorder.none,
                ),
                // With nothing typed, the keyboard's send key puts the keyboard away instead, like "Done".
                onSubmitted: (text) {
                  if (text.trim().isEmpty) {
                    focusNode.unfocus();
                    return;
                  }
                  onSend();
                  focusNode.requestFocus();
                },
              ),
            ),
            emoteButton,
            // The send button's room opens and closes smoothly, so the emote button glides aside instead of jumping,
            // while the button itself grows and fades in, or shrinks and fades out.
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final shown = controller.text.trim().isNotEmpty;
                return IgnorePointer(
                  ignoring: !shown,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: shown ? _sendButtonRoom : 6.0,
                    height: height,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: _sendButtonRoom,
                        maxWidth: _sendButtonRoom,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2.0, 0.0, 6.0, 0.0),
                          child: Center(
                            child: AnimatedScale(
                              scale: shown ? 1.0 : 0.6,
                              duration: const Duration(milliseconds: 200),
                              curve: shown ? Curves.easeOutBack : Curves.easeIn,
                              child: AnimatedOpacity(
                                opacity: shown ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 160),
                                child: _SendButton(ready: ready, onSend: onSend),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Width the send button takes in the field: 2 before it, the 32 point button, 6 to the field's end.
const double _sendButtonRoom = 40.0;

class _SendButton extends StatelessWidget {
  final bool ready;
  final VoidCallback onSend;

  const _SendButton({required this.ready, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pressable(
      onTap: onSend,
      haptic: true,
      semanticLabel: AppLocalizations.of(context).sendMessage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Grey until the chat is connected: sending then only says it isn't.
          color: ready ? scheme.primary : scheme.onSurface.withValues(alpha: 0.16),
        ),
        child: Icon(Icons.arrow_upward_rounded, size: 20.0, color: ready ? scheme.onPrimary : scheme.onSurfaceVariant),
      ),
    );
  }
}

/// A glass card above the composer, for hints, uploads, the reply and the suggestions.
class _DockCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DockCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
    child: Glass(
      shape: Glass.card,
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    ),
  );
}

/// The autocompletion above the composer: chatters, custom commands and emotes matching the word being typed.
class _Suggestions extends StatelessWidget {
  final List<AutocompletionItem> items;

  const _Suggestions({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _DockCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 52.0 * 4.5),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          children: [
            for (final item in items)
              Tile(
                onTap: item.onTap,
                onLongPress: item.onLongPress,
                prefix: item.prefix,
                title: item.title,
                subtitle: item.subtitle,
              ),
          ],
        ),
      ),
    );
  }
}

/// In place of the text field while there is no login to send with: starts the Twitch login, after which the chat
/// goes on as that account.
class _LoginToChatButton extends StatelessWidget {
  const _LoginToChatButton();

  @override
  Widget build(BuildContext context) => WarmsUpTwitchLogin(
    child: SizedBox(
      height: _composerHeightOf(context),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: ChatColors.twitchPurple,
          foregroundColor: ChatColors.onTwitchPurple,
          shape: const StadiumBorder(),
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        onPressed: () => showTwitchLogin(context),
        icon: SvgPicture.asset(
          'assets/emote_providers/twitch.svg',
          width: 18.0,
          height: 18.0,
          colorFilter: const ColorFilter.mode(ChatColors.onTwitchPurple, BlendMode.srcIn),
        ),
        label: Text(AppLocalizations.of(context).logInToChat),
      ),
    ),
  );
}

/// The message the next one replies to, above the composer: who wrote it and its text on one line, with a button to
/// cancel the reply.
class _ReplyCard extends StatelessWidget {
  final ComposerDraft draft;

  const _ReplyCard({required this.draft});

  @override
  Widget build(BuildContext context) => BlocBuilder<ComposerDraft, ChannelMessageChat?>(
    bloc: draft,
    builder: (context, reply) {
      if (reply == null) return const SizedBox.shrink();
      final theme = Theme.of(context);
      final name = reply.user.displayName ?? reply.user.login ?? '';
      return _DockCard(
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 3.0,
                margin: const EdgeInsets.fromLTRB(14.0, 10.0, 10.0, 10.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${AppLocalizations.of(context).replyingTo} '),
                            TextSpan(
                              text: name,
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(color: ChatColors.of(context).muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(reply.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              Pressable(
                onTap: () => draft.replyTo(null),
                semanticLabel: AppLocalizations.of(context).cancel,
                child: const SizedBox.square(dimension: 44.0, child: Icon(Icons.close_rounded, size: 20.0)),
              ),
              const SizedBox(width: 4.0),
            ],
          ),
        ),
      );
    },
  );
}

/// The chat of a [ChannelView], behind the composer. Kept apart from the composer so typing doesn't rebuild it, and it
/// reads only the view padding: [MediaQuery.of] would also rebuild it on every frame of the keyboard animation, which
/// changes the insets.
class _ChannelChat extends StatelessWidget {
  final Channel channel;

  /// Height of the controls over the bottom of the chat.
  final double bottomInset;

  const _ChannelChat({required this.channel, required this.bottomInset});

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    // Touching the chat puts the keyboard and the emote panel away, like in Messages.
    onPointerDown: (e) {
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      context.read<EmotePanelCubit>().hide();
    },
    child: ChatView(
      padding: MediaQuery.viewPaddingOf(context).copyWith(bottom: bottomInset),
      channel: channel,
    ),
  );
}

/// Whispers that arrive while ColdChat is closed never reach it, and Twitch gives apps no history to fetch them
/// from later. Says so once, with a way to read them on Twitch, until dismissed.
class _WhisperHistoryHint extends StatefulWidget {
  const _WhisperHistoryHint();

  @override
  State<_WhisperHistoryHint> createState() => _WhisperHistoryHintState();
}

class _WhisperHistoryHintState extends State<_WhisperHistoryHint> {
  late bool dismissed = context.read<SettingsRepository>().whisperHistoryHintDismissed;

  @override
  Widget build(BuildContext context) {
    if (dismissed) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return _DockCard(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(l10n.whisperHistoryHint),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    unawaited(context.read<SettingsRepository>().dismissWhisperHistoryHint());
                    setState(() => dismissed = true);
                  },
                  child: Text(l10n.gotIt),
                ),
                TextButton(
                  // Twitch has no link to its whisper inbox; on a phone with the Twitch app this opens the app.
                  onPressed: () => launchUrl(Uri.parse('https://www.twitch.tv/'), mode: LaunchMode.externalApplication),
                  child: Text(l10n.openTwitch),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
