import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/separator.dart';
import '../components/tile.dart';
import '../data/message_trigger.dart';
import '../data/repositories/trigger_repository.dart';
import '../data/trigger_input.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

class MessageTriggerModal extends StatefulWidget {
  final MessageTrigger? messageTrigger;

  const MessageTriggerModal({
    super.key,
    this.messageTrigger,
  });

  @override
  State<MessageTriggerModal> createState() => _MessageTriggerModalState();
}

class _MessageTriggerModalState extends State<MessageTriggerModal> {
  MessageTriggerType type = MessageTriggerType.mention;
  TextEditingController patternController = TextEditingController();
  bool enableRegex = false;
  bool caseSensitive = false;

  @override
  void initState() {
    type = MessageTriggerType.values[widget.messageTrigger?.type ?? MessageTriggerType.mention.index];
    patternController.text = widget.messageTrigger?.pattern ?? '';
    enableRegex = widget.messageTrigger?.enableRegex ?? false;
    caseSensitive = widget.messageTrigger?.caseSensitive ?? false;
    super.initState();
  }

  @override
  void dispose() {
    patternController.dispose();
    super.dispose();
  }

  MessageTriggerInput get _input =>
      parseMessageTriggerInput(patternController.text, enableRegex: enableRegex, caseSensitive: caseSensitive);

  String? _errorText(BuildContext context, MessageTriggerInput input) {
    final line = input.invalidLine;
    if (line == null) return null;
    return input.entries.length > 1
        ? AppLocalizations.of(context).invalidRegexLine(line)
        : AppLocalizations.of(context).invalidRegex;
  }

  @override
  Widget build(BuildContext context) {
    final input = _input;
    final canSave = input.entries.isNotEmpty && input.invalidLine == null;
    return ListView(
      shrinkWrap: true,
      children: [
        ModalHeader(title: AppLocalizations.of(context).messageTrigger),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: TextField(
            controller: patternController,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).pattern,
              helperText: AppLocalizations.of(context).messageTriggerPatternHelp,
              helperMaxLines: 3,
              border: InputBorder.none,
              filled: true,
              errorText: _errorText(context, input),
              errorMaxLines: 2,
            ),
            onChanged: (text) => setState(() {}),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ChoiceChip(
              label: Text(AppLocalizations.of(context).mention),
              selected: type == MessageTriggerType.mention,
              onSelected: (bool selected) => setState(() {
                type = MessageTriggerType.mention;
              }),
            ),
            ChoiceChip(
              label: Text(AppLocalizations.of(context).block),
              selected: type == MessageTriggerType.block,
              onSelected: (bool selected) => setState(() {
                type = MessageTriggerType.block;
              }),
            ),
          ],
        ),
        Tile(
          title: AppLocalizations.of(context).enableRegex,
          prefix: Checkbox(
            value: enableRegex,
            onChanged: (bool? value) => setState(() => enableRegex = value ?? !enableRegex),
          ),
          onTap: () => setState(() => enableRegex = !enableRegex),
        ),
        Tile(
          title: AppLocalizations.of(context).caseSensitive,
          prefix: Checkbox(
            value: caseSensitive,
            onChanged: (bool? value) => setState(() => caseSensitive = value ?? !caseSensitive),
          ),
          onTap: () => setState(() => caseSensitive = !caseSensitive),
        ),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 32.0,
              child: Separator(axis: Axis.vertical),
            ),
            Expanded(
              child: InkWell(
                onTap: !canSave
                    ? null
                    : () async {
                        final triggers = context.read<TriggerRepository>();
                        Navigator.of(context).pop();
                        await triggers.saveMessageTriggerEntries(
                          input.entries,
                          type: type,
                          existing: widget.messageTrigger,
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).save,
                      style: TextStyle(
                        color: !canSave ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
