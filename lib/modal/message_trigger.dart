import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/separator.dart';
import '../components/tile.dart';
import '../data/message_trigger.dart';
import '../data/repositories/trigger_repository.dart';
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

  bool get _invalidRegex => enableRegex && !MessageTrigger.isValidRegex(patternController.text.trim());

  bool get _canSave => patternController.text.isNotEmpty && !_invalidRegex;

  @override
  Widget build(BuildContext context) => ListView(
    shrinkWrap: true,
    children: [
      ModalHeader(title: AppLocalizations.of(context).messageTrigger),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
        child: TextField(
          controller: patternController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).pattern,
            border: InputBorder.none,
            filled: true,
            errorText: _invalidRegex ? AppLocalizations.of(context).invalidRegex : null,
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
              onTap: !_canSave
                  ? null
                  : () async {
                      Navigator.of(context).pop();

                      patternController.text = patternController.text.trim();

                      final triggers = context.read<TriggerRepository>();
                      if (widget.messageTrigger == null) {
                        await triggers.addMessageTrigger(
                          MessageTrigger(
                            pattern: patternController.text,
                            enableRegex: enableRegex,
                            caseSensitive: caseSensitive,
                            type: type.index,
                          ),
                        );
                      } else {
                        widget.messageTrigger!.type = type.index;
                        widget.messageTrigger!.pattern = patternController.text;
                        widget.messageTrigger!.enableRegex = enableRegex;
                        widget.messageTrigger!.caseSensitive = caseSensitive;
                        await triggers.saveMessageTrigger(widget.messageTrigger!);
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).save,
                    style: TextStyle(
                      color: !_canSave ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
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
