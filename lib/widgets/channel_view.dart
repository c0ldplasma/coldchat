import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/twitch/twitch.dart';
import '../components/bottom_bar.dart';
import '../components/modal.dart';
import '../components/surface.dart';
import '../components/tile.dart';
import '../data/emote.dart';
import '../data/filesharing/upload_queue_cubit.dart';
import '../data/filesharing/upload_task.dart';
import '../data/repositories/custom_command_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../l10n/app_localizations.dart';
import '../modal/login_flow.dart';
import '../theme/coldchat_theme.dart';
import '../tmi/channel/channel.dart';
import '../tmi/channel/messages/channel_message_chat.dart';
import '../tmi/whispers/whisper_channel.dart';
import '../tmi/whispers/whispers.dart';
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

  static ChannelViewState? of(BuildContext context) => context.findAncestorStateOfType<ChannelViewState>();
}

enum AutocompletionType {
  emote,
  user,
  customCommand,
}

class AutocompletionItem {
  final Widget? prefix;
  final String title;
  final String? subtitle;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Widget? shortened;
  final AutocompletionType type;

  AutocompletionItem({
    this.prefix,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.shortened,
    required this.type,
  });
}

class ChannelViewState extends State<ChannelView> {
  final FocusNode textFocusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  bool spamming = false;
  bool emoteKeyboard = false;
  // The emote menu is open to choose the button's emote (long-press on it).
  bool pickingButtonIcon = false;
  ChannelMessageChat? replyChannelMessageChat;
  StreamSubscription<UploadTask>? _uploadSubscription;
  // Rebuild the composer when the channel is joined or the sending connection drops, see [Channel.canSend].
  final List<StreamSubscription<Object?>> _canSendSubscriptions = [];

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
    replyChannelMessageChat = draft.reply;

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
    void updateCanSend(Object? _) {
      if (mounted) setState(() {});
    }

    _canSendSubscriptions.addAll([
      widget.channel.stream.listen(updateCanSend),
      widget.channel.client.transmitter.stream.listen(updateCanSend),
      widget.channel.transmitterJoin.stream.listen(updateCanSend),
    ]);
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

  void setReplyChannelMessageChat(ChannelMessageChat? channelMessageChat) {
    setState(() {
      replyChannelMessageChat = channelMessageChat;
    });
  }

  Future<void> sendMessage() async {
    // TODO: Implement reactions here

    var text = textEditingController.text;

    final textSplits = text.trim().split(' ');
    if (textSplits.isNotEmpty) {
      final customCommand = context.read<CustomCommandRepository>().commandFor(textSplits.first);
      if (customCommand != null) {
        text = customCommand.command;
        text = text.replaceAllMapped(
          RegExp(r'{\d*}'),
          (match) {
            final matchText = match.group(0) ?? '{}';
            final matchContent = matchText.substring(1, matchText.length - 1);
            final index = int.tryParse(matchContent);
            if (index != null && index < textSplits.length && index > 0) {
              return textSplits[index];
            }
            return '';
          },
        );
        text = text.replaceAllMapped(
          RegExp(r'{\d*\+}'),
          (match) {
            final matchText = match.group(0) ?? '{+}';
            final matchContent = matchText.substring(1, matchText.length - 2);
            final index = int.tryParse(matchContent);
            if (index != null && index < textSplits.length && index > 0) {
              return textSplits.skip(index).join(' ');
            }
            return '';
          },
        );
      }
    }

    final whisperCommand = _whisperCommand.firstMatch(text.trim());
    if (whisperCommand != null || widget.channel is WhisperChannel) {
      final original = textEditingController.text;
      setReplyChannelMessageChat(null);
      textEditingController.clear();
      final whispers = widget.channel.client.whispers;
      final login = whisperCommand?.group(1);
      final whisperText = whisperCommand?.group(2)?.trim() ?? '';
      unawaited(
        _sendWhisper(
          () => login == null
              ? widget.channel.send(text)
              : whisperText.isEmpty
              ? whispers.openAndFocus(login)
              : whispers.sendTo(login, whisperText),
          original,
        ),
      );
      return;
    }

    // Not joined yet (e.g. the JOIN still waits for the rate limit after an account switch): Twitch would drop the
    // message, so keep it in the composer and say so instead of clearing it.
    if (!widget.channel.canSend) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).messageNotSentNotConnected)));
      return;
    }

    unawaited(
      widget.channel.send(
        text,
        tags: {
          if (replyChannelMessageChat != null) 'reply-parent-msg-id': replyChannelMessageChat!.id,
        },
      ),
    );

    setReplyChannelMessageChat(null);

    textEditingController.clear();
  }

  // `/w <user> [message]`, as on Twitch. Twitch no longer accepts it over IRC, so it goes through Helix.
  static final RegExp _whisperCommand = RegExp(r'^/(?:w|whisper)\s+@?(\S+)(?:\s+(.*))?$', dotAll: true);

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

  /// Shows why a whisper couldn't be sent or opened, with a "Sign in" action when a new login fixes it.
  static void showWhisperError(ScaffoldMessengerState messenger, NavigatorState navigator, Object error) {
    final text = whisperErrorText(messenger.context, error);
    if (whisperErrorNeedsSignIn(error)) {
      showSignInSnackBar(messenger, navigator, text);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }

  /// Whether signing in (again) fixes [error]: no login, or one from before ColdChat supported whispers.
  static bool whisperErrorNeedsSignIn(Object error) => error is WhisperUnavailableException;

  static String whisperErrorText(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is WhisperUnavailableException) {
      return error.missingScope ? l10n.whisperNeedsScope : l10n.whisperNeedsLogin;
    }
    if (error is WhisperUserNotFoundException) return l10n.whisperUserNotFound;
    if (error is TwitchRequestException) return l10n.whisperFailed(error.message);
    return l10n.whisperFailed('$error');
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
    final text = textEditingController.text;
    final selection = textEditingController.selection;
    final at = selection.isValid ? selection.end : text.length;

    final needsLeadingSpace = at > 0 && !text.substring(0, at).endsWith(' ');
    final insertion = '${needsLeadingSpace ? ' ' : ''}$url ';
    final updated = text.replaceRange(selection.isValid ? selection.start : at, at, insertion);

    textEditingController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: (selection.isValid ? selection.start : at) + insertion.length),
    );
  }

  @override
  void dispose() {
    unawaited(_uploadSubscription?.cancel());
    for (final subscription in _canSendSubscriptions) {
      unawaited(subscription.cancel());
    }
    final selection = textEditingController.selection;
    widget.channel.composerDraft.save(
      text: textEditingController.text,
      caret: selection.isValid ? selection.end : -1,
      reply: replyChannelMessageChat,
    );
    textEditingController.dispose();
    textFocusNode.dispose();
    super.dispose();
  }

  List<AutocompletionItem> getAutocompletionItems() {
    if (textEditingController.text.split(' ').last.length < 2) return [];
    final currentSearch = textEditingController.text.split(' ').last.toLowerCase();

    final chatSettings = context.read<SettingsRepository>().chatSettings;

    final matchingEmotes =
        (widget.channel.channelEmotes.state +
                widget.channel.client.globalEmotes.state +
                widget.channel.client.twitchUserEmotes.state)
            .where((emote) {
              return (chatSettings.emoteAutocompletionWithColon ? currentSearch.startsWith(':') : true) &&
                  ':${emote.name}:'.toLowerCase().contains(currentSearch);
            })
            .toList();
    // Emotes whose name starts with the search go first, then the ones that
    // only match further into the name. Stable, so each group keeps its order.
    final emotePrefix = currentSearch.startsWith(':') ? currentSearch : ':$currentSearch';
    bool startsWithSearch(Emote emote) => ':${emote.name}:'.toLowerCase().startsWith(emotePrefix);
    final sortedEmotes = [
      ...matchingEmotes.where(startsWithSearch),
      ...matchingEmotes.whereNot(startsWithSearch),
    ];

    final chatters = widget.channel.recentChatters;
    final matchingChatters = chatters.where((chatter) {
      return (chatSettings.userAutocompletionWithAt ? currentSearch.startsWith('@') : true) &&
          '@${chatter.login}'.toLowerCase().contains(currentSearch);
    });

    return [
      for (final user in matchingChatters)
        AutocompletionItem(
          type: AutocompletionType.user,
          prefix: const Icon(Icons.person_outline_rounded),
          shortened: Text(
            '@${user.displayName ?? user.login}',
            style: TextStyle(
              color: ChatColors.of(context).nameColor(user.color, Theme.of(context).colorScheme),
              fontWeight: FontWeight.bold,
            ),
          ),
          title: user.displayName ?? user.login!,
          subtitle: user.login,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${user.login} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
      for (final customCommand in context.read<CustomCommandRepository>().commandsStartingWith(
        textEditingController.text,
      ))
        AutocompletionItem(
          type: AutocompletionType.customCommand,
          prefix: const Icon(Icons.keyboard_command_key_rounded),
          shortened: Text(customCommand.trigger),
          title: customCommand.trigger,
          subtitle: customCommand.command,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${customCommand.trigger} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
      for (final emote in sortedEmotes)
        AutocompletionItem(
          type: AutocompletionType.emote,
          prefix: EmoteGlyph(
            emote: emote,
            size: 24.0,
            image: () => CachedNetworkImage(imageUrl: emote.mipmap.last, width: 24.0, height: 24.0),
          ),
          shortened: EmoteGlyph(
            emote: emote,
            size: 24.0,
            image: () => CachedNetworkImage(imageUrl: emote.mipmap.last, width: 24.0, height: 24.0),
          ),
          title: emote.name,
          subtitle: emote.provider.name,
          onTap: () {
            final splits = textEditingController.text.split(' ');
            splits.removeLast();
            splits.add('${emote.code ?? emote.name} ');
            textEditingController.text = splits.join(' ');
            textEditingController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: textEditingController.text.length,
              ),
            );
            setState(() {});
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) {
              final currentFocus = FocusScope.of(context);
              if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
            child: ChatView(
              padding: MediaQuery.of(context).viewPadding,
              channel: widget.channel,
            ),
          ),
          // child: Container(),
        ),
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
              if (replyChannelMessageChat != null)
                Surface(
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
                            ChatMessage(message: replyChannelMessageChat!),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Surface(
                          onTap: () => setReplyChannelMessageChat(null),
                          borderRadius: BorderRadius.circular(40.0),
                          // type: SurfaceType.error,
                          child: const Icon(Icons.close_outlined),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                  ),
                ),
              Surface(
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
              // Surface(
              //   type: SurfaceType.tertiary,
              //   child: SizedBox(
              //     height: 56.0,
              //     child: ListView(
              //       padding: EdgeInsets.zero,
              //       scrollDirection: Axis.horizontal,
              //       children: [
              //         for (final autocompletionItem in getAutocompletionItems())
              //           InkWell(
              //             onTap: autocompletionItem.onTap,
              //             onLongPress: autocompletionItem.onLongPress,
              //             child: ConstrainedBox(
              //               constraints: BoxConstraints(minWidth: 56.0),
              //               child: Padding(
              //                 padding: const EdgeInsets.all(12.0),
              //                 child: autocompletionItem.shortened,
              //               ),
              //             ),
              //             // title: autocompletionItem.title,
              //             // subtitle: autocompletionItem.subtitle,
              //           ),
              //       ],
              //     ),
              //   ),
              // ),
              // if (textEditingController.text.split(' ').last.length >= 2 && (widget.channel.channelEmotes.state + widget.channel.client.globalEmotes.state).any((emote) => emote.name.toLowerCase().contains(textEditingController.text.split(' ').last.toLowerCase())))
              //   Ink(
              //     color: Theme.of(context).colorScheme.secondaryContainer,
              //     child: SizedBox(
              //       height: 32.0 + 24.0,
              //       child: ListView(
              //         scrollDirection: Axis.horizontal,
              //         children: [
              //           for (final emote in (widget.channel.channelEmotes.state + widget.channel.client.globalEmotes.state).where((emote) => emote.name.toLowerCase().contains(textEditingController.text.split(' ').last.toLowerCase())))
              //             Tooltip(
              //               message: emote.name,
              //               child: InkWell(
              //                 onTap: () {
              //                   final splits = textEditingController.text.split(' ');
              //                   splits.removeLast();
              //                   splits.add('${emote.code ?? emote.name} ');
              //                   textEditingController.text = splits.join(' ');
              //                   textEditingController.selection = TextSelection.fromPosition(
              //                     TextPosition(
              //                       offset: textEditingController.text.length,
              //                     ),
              //                   );
              //                   setState(() {});
              //                 },
              //                 child: Padding(
              //                   padding: const EdgeInsets.all(12.0),
              //                   child: Image.network(
              //                     emote.mipmap.last,
              //                   ),
              //                 ),
              //               ),
              //             ),
              //         ],
              //       ),
              //     ),
              //   ),

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
                      child: TextField(
                        controller: textEditingController,
                        focusNode: textFocusNode,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          hintText: widget.channel is WhisperChannel
                              ? AppLocalizations.of(context)
                                    .whisperTo((widget.channel as WhisperChannel).partnerDisplayName)
                              : widget.channel.canSend
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
                      onLongPress: () {
                        setState(() {
                          spamming = !spamming;
                        });
                      },
                      child: SizedBox(
                        width: 48.0,
                        height: 48.0,
                        child: Icon(
                          spamming ? Icons.send_and_archive_rounded : Icons.send_rounded,
                          color: widget.channel.canSend
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                              final cursorPosition = max(0, textEditingController.selection.baseOffset);
                              if (textEditingController.text.isEmpty ||
                                  cursorPosition >= textEditingController.text.length ||
                                  textEditingController.text[cursorPosition] != ' ') {
                                text = '$text ';
                              }
                              if (cursorPosition > 0 && textEditingController.text[cursorPosition - 1] != ' ') {
                                text = ' $text';
                              }
                              textEditingController.text =
                                  textEditingController.text.substring(0, cursorPosition) +
                                  text +
                                  textEditingController.text.substring(cursorPosition);
                              textEditingController.selection = TextSelection.fromPosition(
                                TextPosition(offset: cursorPosition + text.length),
                              );
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

  void addSplit(String? text) {
    if (text == null) return;
    setState(() {
      final splits = textEditingController.text.split(' ');
      splits.add(text);
      splits.removeWhere((element) => element.isEmpty);
      textEditingController.text = splits.join(' ');
      textEditingController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: textEditingController.text.length,
        ),
      );
    });
  }
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
