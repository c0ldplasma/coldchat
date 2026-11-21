import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/modal.dart';
import '../components/tile.dart';
import '../data/repositories/custom_command_repository.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';
import 'custom_command.dart';

class CustomCommandsModal extends StatelessWidget {
  const CustomCommandsModal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: context.read<CustomCommandRepository>().changes,
    builder: (context, _) {
      final repository = context.read<CustomCommandRepository>();
      return ListView(
        shrinkWrap: true,
        children: [
          ModalHeader(title: AppLocalizations.of(context).customCommands),
          for (final customCommand in repository.commands) ...[
            Tile(
              onTap: () => Modal.show(
                context: context,
                child: CustomCommandModal(customCommand: customCommand),
              ),
              prefix: const Icon(Icons.keyboard_command_key_rounded),
              suffix: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: () => repository.delete(customCommand),
                child: const Icon(Icons.delete_forever_rounded),
              ),
              title: customCommand.trigger,
              subtitle: customCommand.command,
            ),
          ],
          Tile(
            onTap: () => Modal.show(
              context: context,
              child: const CustomCommandModal(),
            ),
            prefix: const Icon(Icons.add_rounded),
            title: AppLocalizations.of(context).newCustomCommand,
          ),
        ],
      );
    },
  );
}
