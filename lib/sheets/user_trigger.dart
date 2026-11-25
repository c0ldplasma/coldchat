import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/separator.dart';
import '../data/repositories/trigger_repository.dart';
import '../data/trigger_input.dart';
import '../data/user_trigger.dart';
import '../l10n/app_localizations.dart';
import 'components/modal_header.dart';

class UserTriggerModal extends StatefulWidget {
  final UserTrigger? userTrigger;

  const UserTriggerModal({
    super.key,
    this.userTrigger,
  });

  @override
  State<UserTriggerModal> createState() => _UserTriggerModalState();
}

class _UserTriggerModalState extends State<UserTriggerModal> {
  UserTriggerType type = UserTriggerType.mention;
  TextEditingController patternController = TextEditingController();

  @override
  void initState() {
    type = UserTriggerType.values[widget.userTrigger?.type ?? UserTriggerType.mention.index];
    patternController.text = widget.userTrigger?.login ?? '';
    super.initState();
  }

  @override
  void dispose() {
    patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logins = parseUserTriggerInput(patternController.text);
    return ListView(
      shrinkWrap: true,
      children: [
        ModalHeader(title: AppLocalizations.of(context).userTrigger),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: TextField(
            controller: patternController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).login,
              helperText: AppLocalizations.of(context).userTriggerLoginHelp,
              helperMaxLines: 2,
              border: InputBorder.none,
              filled: true,
            ),
            onChanged: (text) => setState(() {}),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ChoiceChip(
              label: Text(AppLocalizations.of(context).mention),
              selected: type == UserTriggerType.mention,
              onSelected: (bool selected) => setState(() {
                type = UserTriggerType.mention;
              }),
            ),
            ChoiceChip(
              label: Text(AppLocalizations.of(context).block),
              selected: type == UserTriggerType.block,
              onSelected: (bool selected) => setState(() {
                type = UserTriggerType.block;
              }),
            ),
          ],
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
                onTap: logins.isEmpty
                    ? null
                    : () async {
                        final triggers = context.read<TriggerRepository>();
                        Navigator.of(context).pop();
                        await triggers.saveUserTriggerLogins(logins, type: type, existing: widget.userTrigger);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).save,
                      style: TextStyle(
                        color: logins.isEmpty
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
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
