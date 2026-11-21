import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../data/message_trigger.dart';
import '../data/repositories/trigger_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';
import 'message_trigger.dart';

class MessageTriggersModal extends StatelessWidget {
  const MessageTriggersModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<TriggerRepository>().messageTriggerChanges,
    builder: (context, _) {
      final repository = context.read<TriggerRepository>();
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).messageTriggers),
          for (final messageTrigger in repository.messageTriggers) ...[
            Tile(
              onTap: () => Modal.show(
                context: context,
                child: MessageTriggerModal(messageTrigger: messageTrigger),
              ),
              prefix: Icon(
                messageTrigger.type == MessageTriggerType.mention.index
                    ? Icons.alternate_email_rounded
                    : Icons.block_rounded,
              ),
              suffix: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: () => repository.deleteMessageTrigger(messageTrigger),
                child: const Icon(Icons.delete_forever_rounded),
              ),
              title: messageTrigger.pattern,
            ),
          ],
          Tile(
            onTap: () => Modal.show(
              context: context,
              child: const MessageTriggerModal(),
            ),
            prefix: const Icon(Icons.add_rounded),
            title: AppLocalizations.of(context).newMessageTrigger,
          ),
        ],
      );
    },
  );
}
