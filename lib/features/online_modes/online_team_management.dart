import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/responsive_screen.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/core/style/theme_provider.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/league_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnlineTeamManagementScreen extends StatefulWidget {
  final String roomId;
  final bool isOwner;
  const OnlineTeamManagementScreen({
    super.key,
    required this.roomId,
    required this.isOwner,
  });

  @override
  State<OnlineTeamManagementScreen> createState() =>
      _OnlineTeamManagementScreenState();
}

class _OnlineTeamManagementScreenState
    extends State<OnlineTeamManagementScreen> {
  late List<int> leaguesIds;
  late Club firstClub;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        leaguesIds = List<int>.from(snapshot.data()!['leagues']);
        firstClub = Club.fromMap(snapshot.data()!['currentClub']);
      }
      if (snapshot.exists && snapshot.data()!['gameState'] == "Started") {
        GoRouter.of(context).pushReplacement('/online_rondo', extra: {
          'roomId': widget.roomId,
          'turns': snapshot.data()!['turns'],
          'leagues': List<int>.from(snapshot.data()!['leagues']),
          'winScore': snapshot.data()!['winScore'],
          'playerTime': snapshot.data()!['playerTime'],
        });
      } else if (snapshot.exists == false) {
        if (widget.isOwner)
          GoRouter.of(context).go('/create');
        else
          GoRouter.of(context).go('/join');
      }
    });
  }

  Future<bool?> showExitConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ProgressHUD(
          child: Builder(builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.confirmExit),
              content: Text(
                  '${AppLocalizations.of(context)!.areYouSureYouWantToLeave}?'),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.cancel),
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(AppLocalizations.of(context)!.yes),
                  onPressed: () async {
                    final progress = ProgressHUD.of(context);
                    progress!.show();
                    final roomRef = FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(widget.roomId);
                    final User? myUser =
                        Provider.of<AuthService>(context, listen: false).myUser;
                    await roomRef
                        .collection('players')
                        .doc(myUser!.uid)
                        .delete();
                    await roomRef.update({
                      'currentPlayersNum': FieldValue.increment(-1),
                    });

                    if (widget.isOwner) {
                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .delete();
                    } else {
                      GoRouter.of(context).pop();
                      GoRouter.of(context).pop();
                    }
                    progress.dismiss();
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool buttonA = true;
    bool buttonB = true;
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    final User? myUser =
        Provider.of<AuthService>(context, listen: false).myUser;

    Future<void> joinTeam(String teamName) async {
      await roomRef.collection('players').doc(myUser!.uid).update({
        'team': teamName,
      });
    }

    Future<void> startGame(List teamB, List teamA) async {
      final roomDoc = await roomRef.get();
      final roomData = roomDoc.data()!;
      if (teamB.length != roomData['playersNum'] / 2 &&
          teamA.length != roomData['playersNum'] / 2) {
        showSnackBar(AppLocalizations.of(context)!.teamsMustBeEven);
        return;
      }
      if (teamA.length == 1) {
        await roomRef.update({
          'gameState': "Started",
          'turns': [
            teamA[0],
            teamB[0],
          ],
        });
      } else if (teamA.length == 2) {
        await roomRef.update({
          'gameState': "Started",
          'turns': [teamA[0], teamB[0], teamA[1], teamB[1]],
        });
      }
    }

    final teamA = [];
    final teamB = [];
    final noTeam = [];
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        showExitConfirmationDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: ResponsiveScreen(
          squarishMainArea: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.roomId)
                .collection('players')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              teamA.clear();
              teamB.clear();
              noTeam.clear();
              for (final p in snapshot.data!.docs) {
                final gameData = p.data() as Map<String, dynamic>;
                if (gameData['team'] == 'A') {
                  teamA.add(gameData);
                } else if (gameData['team'] == 'B') {
                  teamB.add(gameData);
                } else {
                  noTeam.add(gameData);
                }
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: [
                    ListView(
                      shrinkWrap: true,
                      children: [
                        Text('${AppLocalizations.of(context)!.team} A',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        ListView.builder(
                          itemCount: teamA.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final player = teamA[index];
                            return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 20,
                                  child: ClipOval(
                                      child: Image.network(player['image']))),
                              title: Text(player['name']),
                            );
                          },
                        ),
                        buttonA
                            ? ListTile(
                                leading: CircleAvatar(
                                    radius: 20,
                                    child: ClipOval(
                                        child: IconButton(
                                      onPressed: () async {
                                        buttonB = true;
                                        buttonA = false;
                                        await joinTeam('A');
                                      },
                                      icon: const Icon(Icons.add),
                                    ))),
                                title: Text(AppLocalizations.of(context)!.join),
                              )
                            : SizedBox(),
                      ],
                    ),
                    ListView(
                      shrinkWrap: true,
                      children: [
                        Text('${AppLocalizations.of(context)!.team} B',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        ListView.builder(
                          itemCount: teamB.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final player = teamB[index];

                            return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 20,
                                  child: ClipOval(
                                      child: Image.network(player['image']))),
                              title: Text(player['name']),
                            );
                          },
                        ),
                        buttonB
                            ? ListTile(
                                leading: CircleAvatar(
                                    radius: 20,
                                    child: ClipOval(
                                        child: IconButton(
                                      onPressed: () async {
                                        buttonB = false;
                                        buttonA = true;
                                        await joinTeam('B');
                                      },
                                      icon: const Icon(Icons.add),
                                    ))),
                                title: Text(AppLocalizations.of(context)!.join),
                              )
                            : SizedBox(),
                      ],
                    ),
                    ListView(
                      shrinkWrap: true,
                      children: [
                        Text(AppLocalizations.of(context)!.players),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: noTeam.length,
                          itemBuilder: (context, index) {
                            final player = noTeam[index];
                            return ListTile(
                              leading: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 20,
                                  child: ClipOval(
                                      child: Image.network(player['image']))),
                              title: Text(player['name']),
                            );
                          },
                        ),
                        !buttonB || !buttonA
                            ? ListTile(
                                leading: CircleAvatar(
                                    radius: 20,
                                    child: ClipOval(
                                        child: IconButton(
                                      onPressed: () async {
                                        buttonB = true;
                                        buttonA = true;
                                        await joinTeam('');
                                      },
                                      icon: const Icon(Icons.add),
                                    ))),
                                title: Text(AppLocalizations.of(context)!.join),
                              )
                            : SizedBox(),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                            '${AppLocalizations.of(context)!.selectedLeagues} (${leaguesIds.length})'),
                        FutureBuilder<List<League>>(
                          future: _dbHelper.getLeaguesByIds(leaguesIds),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text(
                                  '${AppLocalizations.of(context)!.error}: ${snapshot.error}');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Text(
                                  AppLocalizations.of(context)!.noLeagues);
                            } else {
                              final leagues = snapshot.data!;
                              return Container(
                                height: 200.0,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: leagues.length,
                                  itemBuilder: (context, index) {
                                    final league = leagues[index];
                                    return Container(
                                      width: 100.0,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 5.0),
                                      child: GridTile(
                                        header: GridTileBar(
                                          title: Text(
                                            league.name,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.green[300],
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context
                                                        .read<ThemeProvider>()
                                                        .themeMode ==
                                                    ThemeMode.dark
                                                ? Colors.grey[400]
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 3,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Image.memory(league.logo),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(AppLocalizations.of(context)!.selectedClub),
                        FutureBuilder<Club>(
                          future: _dbHelper.getClubsById(firstClub.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else if (!snapshot.hasData) {
                              return Text(
                                  AppLocalizations.of(context)!.noClubs);
                            } else {
                              final club = snapshot.data!;
                              return Container(
                                height: 300,
                                margin: EdgeInsets.symmetric(horizontal: 5.0),
                                child: GridTile(
                                  header: GridTileBar(
                                    title: Text(
                                      club.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.green[300],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context
                                                  .read<ThemeProvider>()
                                                  .themeMode ==
                                              ThemeMode.dark
                                          ? Colors.grey[400]
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Image.memory(club.logo!),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          rectangularMenuArea: widget.isOwner
              ? Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await startGame(teamA, teamB);
                      },
                      child: Text(AppLocalizations.of(context)!.start),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CopyLinkWidget(
                      link:
                          'https://football-challenges.web.app/room/${widget.roomId}',
                    ),
                  ],
                )
              : SizedBox(),
        ),
      ),
    );

    ;
  }
}

class CopyLinkWidget extends StatelessWidget {
  final String link;

  const CopyLinkWidget({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: link));
        showSnackBar(
          '${AppLocalizations.of(context)!.linkCopiedToClipboard}!',
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.green[500],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          link,
          style: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
    );
  }
}
