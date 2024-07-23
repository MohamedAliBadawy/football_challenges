// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'settings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showCustomNameDialog(BuildContext context, AuthService authService) {
  showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => CustomNameDialog(
            animation: animation,
            authService: authService,
          ));
}

class CustomNameDialog extends StatefulWidget {
  final Animation<double> animation;
  final authService;
  const CustomNameDialog(
      {required this.animation, required this.authService, super.key});

  @override
  State<CustomNameDialog> createState() => _CustomNameDialogState();
}

class _CustomNameDialogState extends State<CustomNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutCubic,
      ),
      child: SimpleDialog(
        title: Text(AppLocalizations.of(context)!.changeName),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 12,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (value) {},
            onSubmitted: (value) async {
              context.read<SettingsController>().setPlayerName(value);
              await context.read<AuthService>().updateDisplayName(value);
              // Player tapped 'Submit'/'Done' on their keyboard.
              Navigator.pop(context);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    _controller.text = context.read<AuthService>().myUser == null
        ? context.read<SettingsController>().playerName.value
        : widget.authService.myUser!.displayName.toString();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
