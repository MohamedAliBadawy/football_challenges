// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/src/main_menu/buttons_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_controller.dart';
import '../../core/audio/sounds.dart';

import '../../core/style/responsive_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveScreen(
        mainAreaProminence: 0.45,
        squarishMainArea: Center(
            child: Column(
          children: [
            Image.asset("assets/FoOtBall_challenges-removebg-preview22.png"),
            Text(
              AppLocalizations.of(context)!.footballChallenges,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Permanent Marker',
                fontSize: 40,
                height: 1,
              ),
            ),
          ],
        )),
        rectangularMenuArea: Consumer<ButtonState>(
          builder: (context, buttonState, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: slideAnimation,
                  child: child,
                );
              },
              child: !buttonState.showFirstButtons &&
                      !buttonState.showSecondButtons
                  ? const FirstColumn()
                  : (buttonState.showSecondButtons &&
                          !buttonState.showFirstButtons
                      ? const LoadingWidget()
                      : (buttonState.showFirstButtons &&
                              !buttonState.showSecondButtons
                          ? const SecondColumn()
                          : const ThirdColumn())),
            );
          },
        ),
      ),
    );
  }
}

class FirstColumn extends StatelessWidget {
  const FirstColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);

            Provider.of<ButtonState>(context, listen: false).showFirst();
          },
          child: Text(
            AppLocalizations.of(context)!.play,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(AppLocalizations.of(context)!.howToPlay),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(AppLocalizations.of(context)!.rule1),
                          Text(AppLocalizations.of(context)!.rule2),
                          Text(AppLocalizations.of(context)!.rule3),
                          Text(AppLocalizations.of(context)!.rule4),
                          Text(AppLocalizations.of(context)!.rule5),
                          Text(AppLocalizations.of(context)!.rule6),
                          Text(AppLocalizations.of(context)!.rule7),
                          const SizedBox(height: 10),
                          Text(AppLocalizations.of(context)!.rule8),
                          Text(AppLocalizations.of(context)!.rule9),
                          Text(AppLocalizations.of(context)!.rule10),
                          Text(AppLocalizations.of(context)!.rule11),
                          Text(AppLocalizations.of(context)!.rule12),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.gotIt),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                });
          },
          child: Text(
            AppLocalizations.of(context)!.howToPlay,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);
            GoRouter.of(context).push('/settings');
          },
          child: Text(
            AppLocalizations.of(context)!.settings,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class SecondColumn extends StatelessWidget {
  const SecondColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton(
          onPressed: () async {
            audioController.playSfx(SfxType.buttonTap);
            if (Provider.of<AuthService>(context, listen: false).myUser !=
                null) {
              Provider.of<ButtonState>(context, listen: false).showSecond();
            } else {
              showSnackBar("You must login to access the online mode");
              await Provider.of<AuthService>(context, listen: false)
                  .signInWithGoogle();
            }
          },
          child: Text(
            AppLocalizations.of(context)!.online,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);
            GoRouter.of(context).push('/offline');
          },
          child: Text(
            AppLocalizations.of(context)!.offline,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);

            Provider.of<ButtonState>(context, listen: false).resetButtons();
          },
          child: Text(
            AppLocalizations.of(context)!.back,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class ThirdColumn extends StatelessWidget {
  const ThirdColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);

            GoRouter.of(context).push('/create');
          },
          child: Text(
            AppLocalizations.of(context)!.createRoom,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);
            GoRouter.of(context).push('/join');
          },
          child: Text(
            AppLocalizations.of(context)!.joinRoom,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () {
            audioController.playSfx(SfxType.buttonTap);

            Provider.of<ButtonState>(context, listen: false).resetButtons();
          },
          child: Text(
            AppLocalizations.of(context)!.back,
            style: const TextStyle(
              fontFamily: 'Permanent Marker',
              fontSize: 25,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  bool _isCopying = false;
  double _progress = 0.0;
  late StreamSubscription<double> _progressSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to the progress stream from the DatabaseHelper
    _progressSubscription =
        DatabaseHelper.instance.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _isCopying = progress < 1.0;
        });
      }

      if (!_isCopying) {
        Provider.of<ButtonState>(context, listen: false).resetButtons();
      }
    });

    // Trigger database initialization
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await DatabaseHelper.instance.database;
  }

  @override
  void dispose() {
    super.dispose();
    _progressSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.initializingDatabase),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: _progress,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        Text('${(_progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}
