import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/bottom_bar.dart';
import '../components/modal.dart';
import '../components/surface.dart';
import '../components/tile.dart';
import '../data/emote_cache.dart';
import '../data/filesharing/upload_queue_cubit.dart';
import '../data/filesharing/upload_task.dart';
import '../data/repositories/custom_command_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../sheets/login.dart';
import '../sheets/whisper_errors.dart';
import '../tmi/channel/can_send.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/composer_draft.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../tools/composer/composer_send.dart';
import '../tools/composer/composer_text.dart';
import '../tools/emotes/autocompletion_matcher.dart';
import 'chat/emote_picker.dart';
import 'chat/upload_queue_bar.dart';
import 'chat_message.dart';
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
  bool emoteKeyboard = false;
  // The emote menu is open to choose the button's emote (long-press on it).
  bool pickingButtonIcon = false;
  // Keeps the autocompletion's emote and chatter lists between rebuilds, see [AutocompletionMatcher].
  final AutocompletionMatcher _autocompletion = AutocompletionMatcher();
  StreamSubscription<UploadTask>? _uploadSubscription;
  StreamSubscription<String>? _mentionSubscription;

  /// The chat above the composer, created once. The composer calls setState on every keystroke; handing Flutter the
  /// same widget again makes it skip the chat instead of rebuilding the list and every visible message.
  late Widget _chat = _ChannelChat(channel: widget.channel);

  @override
  void didUpdateWidget(ChannelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel != oldWidget.channel) _chat = _ChannelChat(channel: widget.channel);
  }

  @override
  void initState() {
    super.initState();
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
    await Modal.show(
      context: context,
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tile(
              title: AppLocalizations.of(context).takePhoto,
              prefix: const Icon(Icons.photo_camera_outlined),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(takeAndUploadPhoto());
              },
            ),
            Tile(
              title: AppLocalizations.of(context).chooseFromLibrary,
              prefix: const Icon(Icons.photo_library_outlined),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(pickAndUploadFromLibrary());
              },
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

    final sortedEmotes = _autocompletion.emotes(
      channelEmotes: widget.channel.channelEmotes.state,
      globalEmotes: widget.channel.client.globals.emotes.state,
      userEmotes: widget.channel.client.globals.twitchUserEmotes.state,
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
    return Column(
      children: [
        Expanded(child: _chat),
        BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UploadQueueBar(channelName: widget.channel.name),
              if (widget.channel is WhisperChannel) const _WhisperHistoryHint(),
              if (widget.channel is WhisperChannel && !widget.channel.client.whispers.hasScope)
                Surface(
                  type: SurfaceType.error,
                  onTap: () => showTwitchLogin(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(AppLocalizations.of(context).whisperNeedsScope)),
                        const SizedBox(width: 8.0),
                        Text(
                          AppLocalizations.of(context).signInAgain,
                          // Only the weight: the color comes from the Surface's DefaultTextStyle.
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              _ReplyBar(draft: widget.channel.composerDraft),
              // Follows the text however it changes (typing, sending clears it, a completion or mention edits it), not
              // only the rebuilds typing causes: sending clears the field without one.
              ListenableBuilder(
                listenable: textEditingController,
                builder: (context, _) => Surface(
                  type: SurfaceType.secondary,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 56.0 * 4.5),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.vertical,
                      children: [
                        for (final autocompletionItem in getAutocompletionItems())
                          Tile(
                            onTap: autocompletionItem.onTap,
                            onLongPress: autocompletionItem.onLongPress,
                            prefix: autocompletionItem.prefix,
                            title: autocompletionItem.title,
                            subtitle: autocompletionItem.subtitle,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
                child: Row(
                  children: [
                    InkWell(
                      onTap: pickAndUploadFiles,
                      child: const SizedBox(
                        width: 48.0,
                        height: 48.0,
                        child: Icon(Icons.attach_file_rounded),
                      ),
                    ),
                    // const Separator(axis: Axis.vertical),
                    Expanded(
                      // The hint says "Connecting to …" until the channel can be written to.
                      child: BlocBuilder<CanSend, bool>(
                        bloc: widget.channel.canSendCubit,
                        builder: (context, canSend) => TextField(
                          controller: textEditingController,
                          focusNode: textFocusNode,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            hintText: widget.channel is WhisperChannel
                                ? AppLocalizations.of(context)
                                      .whisperTo((widget.channel as WhisperChannel).partnerDisplayName)
                                : canSend
                                ? AppLocalizations.of(context).sendMessageIn(widget.channel.name)
                                : AppLocalizations.of(context).channelConnecting(widget.channel.name),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (text) {
                            unawaited(sendMessage());
                            textFocusNode.requestFocus();
                          },
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          emoteKeyboard = !emoteKeyboard;
                          pickingButtonIcon = false;
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          emoteKeyboard = true;
                          pickingButtonIcon = true;
                        });
                      },
                      child: const SizedBox(
                        width: 48.0,
                        height: 48.0,
                        child: Center(
                          child: EmoteButtonIconView(),
                        ),
                      ),
                    ),
                    // const Separator(axis: Axis.vertical),
                    InkWell(
                      onTap: sendMessage,
                      child: SizedBox(
                        width: 48.0,
                        height: 48.0,
                        child: BlocBuilder<CanSend, bool>(
                          bloc: widget.channel.canSendCubit,
                          builder: (context, canSend) => Icon(
                            Icons.send_rounded,
                            color: canSend
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Slides open and closed like a keyboard instead of popping in. The
              // AnimatedSwitcher keeps the picker mounted while it collapses.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                reverseDuration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  alignment: const Alignment(-1.0, -1.0),
                  child: child,
                ),
                child: !emoteKeyboard
                    ? const SizedBox.shrink(key: ValueKey(false))
                    : SizedBox(
                        key: const ValueKey(true),
                        height: 350.0,
                        child: EmotePicker(
                          client: widget.channel.client,
                          channel: widget.channel,
                          onPickButtonIcon: pickingButtonIcon
                              ? (emote) async {
                                  if (await chooseEmoteButtonIcon(context, emote) && mounted) {
                                    setState(() {
                                      emoteKeyboard = false;
                                      pickingButtonIcon = false;
                                    });
                                  }
                                }
                              : null,
                          getFieldInput: () => textEditingController.text,
                          setFieldInput: (text) async {
                            setState(() {
                              textEditingController.text = text;
                              textEditingController.selection = TextSelection.fromPosition(
                                TextPosition(offset: textEditingController.text.length),
                              );
                            });
                          },
                          insertFieldInput: (text) async {
                            setState(() {
                              textEditingController.value = insertWord(textEditingController.value, text);
                            });
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The message the next one replies to, above the composer, with a button to cancel the reply.
class _ReplyBar extends StatelessWidget {
  final ComposerDraft draft;

  const _ReplyBar({required this.draft});

  @override
  Widget build(BuildContext context) => BlocBuilder<ComposerDraft, ChannelMessageChat?>(
    bloc: draft,
    builder: (context, reply) {
      if (reply == null) return const SizedBox.shrink();
      return Surface(
        type: SurfaceType.error,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Text(AppLocalizations.of(context).replyingTo),
                  ),
                  ChatMessage(message: reply),
                ],
              ),
            ),
            SizedBox(
              width: 40.0,
              height: 40.0,
              child: Surface(
                onTap: () => draft.replyTo(null),
                borderRadius: BorderRadius.circular(40.0),
                child: const Icon(Icons.close_outlined),
              ),
            ),
            const SizedBox(width: 12.0),
          ],
        ),
      );
    },
  );
}

/// The chat of a [ChannelView]. Kept apart from the composer so typing doesn't rebuild it, and it reads only the view
/// padding: [MediaQuery.of] would also rebuild it on every frame of the keyboard animation, which changes the insets.
class _ChannelChat extends StatelessWidget {
  final Channel channel;

  const _ChannelChat({required this.channel});

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (e) {
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    },
    child: ChatView(
      padding: MediaQuery.viewPaddingOf(context),
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
    return Surface(
      type: SurfaceType.tertiary,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
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
