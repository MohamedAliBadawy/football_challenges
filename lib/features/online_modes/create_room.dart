import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/features/offline_modes/same_phone/selection_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  Future<void> _createRoom() async {
    final DatabaseHelper _dbHelper = DatabaseHelper.instance;
    final User? myUser =
        Provider.of<AuthService>(context, listen: false).myUser;
    final roomName = Provider.of<SelectionProvider>(context, listen: false)
        .roomNameController
        .text;
    final password =
        Provider.of<SelectionProvider>(context, listen: false).isPrivate
            ? Provider.of<SelectionProvider>(context, listen: false)
                .passwordController
                .text
            : null;
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc();
    final leagues =
        Provider.of<SelectionProvider>(context, listen: false).leagues;
    final club = Provider.of<SelectionProvider>(context, listen: false).club;
    final selectedScore =
        Provider.of<SelectionProvider>(context, listen: false).selectedScore;
    final selectedTime =
        Provider.of<SelectionProvider>(context, listen: false).selectedTime;

    if (Provider.of<SelectionProvider>(context, listen: false)
        .roomNameController
        .text
        .isEmpty) {
      showSnackBar(AppLocalizations.of(context)!.roomNameIsEmpty);
      return;
    } else if (Provider.of<SelectionProvider>(context, listen: false)
            .isPrivate &&
        Provider.of<SelectionProvider>(context, listen: false)
            .passwordController
            .text
            .isEmpty) {
      showSnackBar(AppLocalizations.of(context)!.passwordIsEmpty);
      return;
    } else if (leagues.isEmpty) {
      showSnackBar(AppLocalizations.of(context)!.youMustSelectLeagues);
      return;
    } else if (club == null) {
      showSnackBar(AppLocalizations.of(context)!.youMustSelectClub);
      return;
    }
    final currentClub = await _dbHelper.getClubsById(club);

    await roomRef.set({
      'roomId': roomRef.id,
      'roomName': roomName,
      'password': password,
      'gameState': "Waiting",
      'leagues': leagues,
      'currentClub': currentClub.toMap(),
      'currentPlayer': null,
      'usedPlayers': [],
      'isClub': false,
      'winScore': selectedScore,
      'playerTime': selectedTime,
      'playersNum':
          Provider.of<SelectionProvider>(context, listen: false).numPlayers,
      'currentPlayersNum': 1,
      'isPrivate':
          Provider.of<SelectionProvider>(context, listen: false).isPrivate,
      'createdAt': FieldValue.serverTimestamp(),
      'teamAScore': 0,
      'teamBScore': 0,
      'turn': 0,
      'turns': [],
    });

    await roomRef.collection('players').doc(myUser!.uid).set({
      'uid': myUser.uid,
      'name': myUser.displayName.toString(),
      'image': myUser.photoURL.toString(),
      'team': '',
    });
    await roomRef.collection('messages').add({
      'sender': 'Game Master',
      'text': 'Find a player that played for ${currentClub.name}',
      'arabicText': 'ابحث عن لاعب لعب ل ${currentClub.name}',
      'reason': null,
      'arabicReason': null,
      'club': currentClub.toMap(),
      'player': null,
      'correct': true,
      'cheating': null,
      'first': true,
      'image': null,
      'uid': "xxx",
      'timestamp': FieldValue.serverTimestamp(),
    });

    GoRouter.of(context).push('/online_team_management', extra: {
      'roomId': roomRef.id,
      'isOwner': true,
      'playersNum':
          Provider.of<SelectionProvider>(context, listen: false).numPlayers
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      child: Builder(builder: (context) {
        return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar:
                AppBar(title: Text(AppLocalizations.of(context)!.createRoom)),
            body: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(children: [
                    TextField(
                      controller:
                          Provider.of<SelectionProvider>(context, listen: false)
                              .roomNameController,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.roomName),
                    ),
                    DropdownButtonFormField<int>(
                      value:
                          Provider.of<SelectionProvider>(context, listen: false)
                              .numPlayers,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.numberOfPlayers),
                      items: [2, 4].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        Provider.of<SelectionProvider>(context, listen: false)
                            .numPlayers = value!;
                      },
                    ),
                    Text("${AppLocalizations.of(context)!.selectLeagues}:"),
                    Consumer<SelectionProvider>(
                      builder: (context, provider, child) {
                        return Wrap(spacing: 8.0, children: [
                          FilterChip(
                            showCheckmark: false,
                            label: provider.leagues.isEmpty
                                ? Text(AppLocalizations.of(context)!.select)
                                : Text(AppLocalizations.of(context)!.edit),
                            selected: provider.leagues.isEmpty ? false : true,
                            onSelected: (bool selected) {
                              GoRouter.of(context).go(
                                '/create/leagues',
                              );
                            },
                          )
                        ]);
                      },
                    ),
                    SizedBox(height: 16),
                    Text("${AppLocalizations.of(context)!.selectClub}:"),
                    Consumer<SelectionProvider>(
                      builder: (context, provider, child) {
                        return FilterChip(
                          showCheckmark: false,
                          label: provider.club == null
                              ? Text(AppLocalizations.of(context)!.select)
                              : Text(AppLocalizations.of(context)!.edit),
                          selected: provider.club == null ? false : true,
                          onSelected: (bool selected) {
                            if (provider.leagues.isEmpty) {
                              showSnackBar(AppLocalizations.of(context)!
                                  .mustSelectLeaguesFirst);
                              return;
                            } else {
                              GoRouter.of(context).go('/create/clubs',
                                  extra: {'clubsIds': provider.leagues});
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.winningScore),
                    Consumer<SelectionProvider>(
                      builder: (context, provider, child) {
                        return Row(
                          children: [1, 2, 3, 4, 5].map((score) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: FilterChip(
                                showCheckmark: false,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(score.toString()),
                                  ],
                                ),
                                selected: provider.selectedScore == score,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    provider.setScore(score);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Text("${AppLocalizations.of(context)!.selectTime}:"),
                    Consumer<SelectionProvider>(
                        builder: (context, provider, child) {
                      return Column(
                        children: [
                          Slider(
                            value: provider.selectedTime.toDouble(),
                            min: 10,
                            max: 60,
                            divisions: 10,
                            label: provider.selectedTime.toString(),
                            onChanged: (double newValue) {
                              provider.setTime(newValue.toInt());
                            },
                          ),
                          Text(
                            '${provider.selectedTime} ${AppLocalizations.of(context)!.seconds}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SwitchListTile(
                            title:
                                Text(AppLocalizations.of(context)!.privateRoom),
                            value: Provider.of<SelectionProvider>(context,
                                    listen: false)
                                .isPrivate,
                            onChanged: (value) {
                              setState(() {
                                Provider.of<SelectionProvider>(context,
                                        listen: false)
                                    .isPrivate = value;
                              });
                            },
                          ),
                          if (Provider.of<SelectionProvider>(context,
                                  listen: false)
                              .isPrivate)
                            TextField(
                              controller: Provider.of<SelectionProvider>(
                                      context,
                                      listen: false)
                                  .passwordController,
                              decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.password),
                            ),
                          ElevatedButton(
                            onPressed: () async {
                              final progress = ProgressHUD.of(context);
                              progress!.show();
                              await _createRoom();
                              progress.dismiss();
                            },
                            child:
                                Text(AppLocalizations.of(context)!.createRoom),
                          ),
                        ],
                      );
                    }),
                  ])),
            ));
      }),
    );
  }
}
