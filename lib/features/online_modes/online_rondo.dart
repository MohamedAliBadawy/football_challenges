import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/audio/audio_controller.dart';
import 'package:football_challenges/core/audio/sounds.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/auth/auth_service.dart';
import 'package:football_challenges/features/online_modes/online_rondo_provider.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/models/player_model.dart';
import 'package:football_challenges/widgets/clubs_search.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:football_challenges/widgets/online_left_message_widget.dart';
import 'package:football_challenges/widgets/online_right_message_widget.dart';

import 'package:football_challenges/widgets/players_search.dart';
import 'package:provider/provider.dart';

class OnlineRondoScreen extends StatefulWidget {
  final String roomId;
  final List<int> leagueIds;
  final List turns;
  final int playerTime;
  final int winScore;

  const OnlineRondoScreen({
    super.key,
    required this.roomId,
    required this.leagueIds,
    required this.playerTime,
    required this.winScore,
    required this.turns,
  });
  @override
  _OnlineRondoScreenState createState() => _OnlineRondoScreenState();
}

class _OnlineRondoScreenState extends State<OnlineRondoScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late OnlineRondoProvider provider;

  @override
  void initState() {
    provider = OnlineRondoProvider()
      ..initialize(
        widget.playerTime,
        widget.winScore,
        context,
        widget.turns,
        widget.roomId,
      );

    super.initState();
  }

  @override
  void dispose() {
    provider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();
    final User? myUser =
        Provider.of<AuthService>(context, listen: false).myUser;
    return ChangeNotifierProvider.value(
      value: provider,
      child: ProgressHUD(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .snapshots(),
              builder: (context, snapshot) {
                provider.context = context;

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
                }

                if (snapshot.hasData) {
                  provider.startTimer(widget.playerTime);
                  final roomData =
                      snapshot.data!.data()! as Map<String, dynamic>;
                  provider.turn = roomData['turn'];
                  provider.isClub = roomData['isClub'];
                  provider.teamAScore = roomData['teamAScore'];
                  provider.teamBScore = roomData['teamBScore'];
                  provider.currentClub = Club.fromMap(roomData['currentClub']);
                  if (roomData['currentPlayer'] != null) {
                    provider.currentPlayer =
                        Player.fromMap(roomData['currentPlayer']);
                    provider.usedPlayers.add(provider.currentPlayer!.id);
                  }
                  provider.evaluate();
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(
                            "${AppLocalizations.of(context)!.team} A",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          )),
                          Flexible(
                              flex: 2,
                              child: Consumer<OnlineRondoProvider>(
                                builder: (context, provider, child) {
                                  return Text(
                                    provider.turns[roomData['turn']]['uid'] ==
                                            myUser!.uid
                                        ? AppLocalizations.of(context)!.yourTurn
                                        : "${provider.turns[roomData['turn']]['name']} ${AppLocalizations.of(context)!.turn}",
                                    style: const TextStyle(
                                      fontFamily: 'Permanent Marker',
                                    ),
                                  );
                                },
                              )),
                          Flexible(
                              child: Text(
                            "${AppLocalizations.of(context)!.team} B",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          )),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "${roomData['teamAScore']}",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            child: Consumer<OnlineRondoProvider>(
                              builder: (context, provider, child) {
                                return Text(
                                  "${AppLocalizations.of(context)!.remainingTime}: ${provider.remainingTime}",
                                  style: const TextStyle(
                                    fontFamily: 'Permanent Marker',
                                  ),
                                );
                              },
                            ),
                          ),
                          Text(
                            "${roomData['teamBScore']}",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const Center(child: Text('404 not found'));
              },
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(widget.roomId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.hasData) {
                          return ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final message = Message.fromMap(
                                  snapshot.data!.docs[index].data()
                                      as Map<String, dynamic>);

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: message.uid == myUser!.uid
                                    ? onlineRightMessageWidget(context, message,
                                        () async {
                                        final progress =
                                            ProgressHUD.of(context);
                                        progress!.show();
                                        audioController.playSfx(
                                            SfxType.refereeWhistleBlow);

                                        late Message m;
                                        int prev = provider.lastTurn();

                                        if (message.correct == true) {
                                          m = Message(
                                              sender: "Game Master",
                                              uid: "xxx",
                                              first: true,
                                              text:
                                                  "${provider.turns[prev]['name']} is not cheating!\n${message.reason}\n${provider.turns[prev]['name']} scored a point for team ${provider.turns[prev]['team']}",
                                              arabicText:
                                                  "${provider.turns[prev]['name']} لم يغش!\n${message.arabicReason}\n${provider.turns[prev]['name']} سجل نقطة لفريقه ${provider.turns[prev]['team']}");
                                          if (provider.turns[prev]['team'] ==
                                              'A') {
                                            provider.teamAScored();
                                          } else if (provider.turns[prev]
                                                  ['team'] ==
                                              'B') provider.teamBScored();
                                        } else {
                                          m = Message(
                                              sender: "Game Master",
                                              uid: "xxx",
                                              first: true,
                                              text:
                                                  "${provider.turns[prev]['name']} is cheating!\n${message.reason}\n${provider.turns[provider.turn]['name']} scored a point for team ${provider.turns[provider.turn]['team']}",
                                              arabicText:
                                                  "${provider.turns[prev]['name']} غشاش!\n${message.arabicReason}\n${provider.turns[provider.turn]['name']} سجل نقطة لفريقه ${provider.turns[provider.turn]['team']}");
                                          if (provider.turns[provider.turn]
                                                  ['team'] ==
                                              'A') {
                                            provider.teamAScored();
                                          } else if (provider
                                                      .turns[provider.turn]
                                                  ['team'] ==
                                              'B') {
                                            provider.teamBScored();
                                          }
                                        }

                                        await provider.cheating(
                                            widget.playerTime, m);
                                        progress.dismiss();
                                      })
                                    : onlineLeftMessageWidget(context, message,
                                        () async {
                                        if (provider.turns[provider.turn]
                                                ['uid'] !=
                                            myUser.uid) {
                                          showSnackBar(
                                              AppLocalizations.of(context)!
                                                  .itsNotYourTurn);

                                          return;
                                        }
                                        final progress =
                                            ProgressHUD.of(context);
                                        progress!.show();
                                        audioController.playSfx(
                                            SfxType.refereeWhistleBlow);

                                        late Message m;
                                        int prev = provider.lastTurn();

                                        if (message.correct == true) {
                                          m = Message(
                                              sender: "Game Master",
                                              uid: "xxx",
                                              first: true,
                                              text:
                                                  "${provider.turns[prev]['name']} is not cheating!\n${message.reason}\n${provider.turns[prev]['name']} scored a point for team ${provider.turns[prev]['team']}",
                                              arabicText:
                                                  "${provider.turns[prev]['name']} لم يغش!\n${message.arabicReason}\n${provider.turns[prev]['name']} سجل نقطة لفريقه ${provider.turns[prev]['team']}");
                                          if (provider.turns[prev]['team'] ==
                                              'A') {
                                            provider.teamAScored();
                                          } else if (provider.turns[prev]
                                                  ['team'] ==
                                              'B') provider.teamBScored();
                                        } else {
                                          m = Message(
                                              sender: "Game Master",
                                              uid: "xxx",
                                              first: true,
                                              text:
                                                  "${provider.turns[prev]['name']} is cheating!\n${message.reason}\n${provider.turns[provider.turn]['name']} scored a point for team ${provider.turns[provider.turn]['team']}",
                                              arabicText:
                                                  "${provider.turns[prev]['name']} غشاش!\n${message.arabicReason}\n${provider.turns[provider.turn]['name']} سجل نقطة لفريقه ${provider.turns[provider.turn]['team']}");
                                          if (provider.turns[provider.turn]
                                                  ['team'] ==
                                              'A') {
                                            provider.teamAScored();
                                          } else if (provider
                                                      .turns[provider.turn]
                                                  ['team'] ==
                                              'B') {
                                            provider.teamBScored();
                                          }
                                        }

                                        await provider.cheating(
                                            widget.playerTime, m);
                                        progress.dismiss();
                                      }),
                              );
                            },
                          );
                        }
                        return const Center(child: Text('404 not found'));
                      }),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.hasData) {
                      final roomData =
                          snapshot.data!.data()! as Map<String, dynamic>;

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: roomData['isClub']
                            ? (myUser!.uid ==
                                    provider.turns[roomData['turn']]['uid']
                                ? ClubsSearchWidget(
                                    readOnly: !(myUser.uid ==
                                        provider.turns[roomData['turn']]
                                            ['uid']),
                                    leagueId: widget.leagueIds,
                                    callback: (suggestion) async {
                                      final progress = ProgressHUD.of(context);
                                      progress!.show();
                                      late Message m;
                                      if (await _dbHelper.validatePlayerInClub(
                                          provider.currentPlayer!.id,
                                          suggestion['id'])) {
                                        if (provider.currentClub!.id ==
                                            suggestion['id']) {
                                          final playerHistory =
                                              await _dbHelper.getAllPlayerClubs(
                                                  provider.currentPlayer!.id,
                                                  widget.leagueIds);
                                          if (playerHistory.length == 1 &&
                                              provider.currentClub!.id ==
                                                  suggestion['id']) {
                                            provider.isClub = false;
                                            m = Message(
                                                correct: true,
                                                sender: provider.turns[provider
                                                    .turn]['name'],
                                                uid: provider.turns[provider
                                                    .turn]['uid'],
                                                image: provider.turns[
                                                    provider.turn]['image'],
                                                text:
                                                    "Find a player that played for ${suggestion['name']}",
                                                arabicText:
                                                    "ابحث عن لاعب لعب لـ ${suggestion['name']}",
                                                reason:
                                                    "${provider.currentPlayer!.name} played only for ${suggestion['name']} in the selected leagues",
                                                arabicReason:
                                                    "${provider.currentPlayer!.name} لعب فقط لـ ${suggestion['name']} في الدوريات المختارة",
                                                club: provider.currentClub);
                                          } else {
                                            m = Message(
                                                correct: false,
                                                sender: provider.turns[provider
                                                    .turn]['name'],
                                                uid: provider.turns[provider
                                                    .turn]['uid'],
                                                image: provider.turns[
                                                    provider.turn]['image'],
                                                text:
                                                    'Find a player that played for ${suggestion['name']}',
                                                arabicText:
                                                    "ابحث عن لاعب لعب لـ ${suggestion['name']}",
                                                reason:
                                                    "${provider.currentPlayer!.name} played for another club in the selected leagues",
                                                arabicReason:
                                                    "${provider.currentPlayer!.name} لعب لنادٍ آخر في الدوريات المختارة",
                                                club: provider.currentClub);
                                          }
                                        } else {
                                          provider.currentClub = Club(
                                              id: suggestion['id'],
                                              name: suggestion['name'],
                                              logo: suggestion['logo'],
                                              leagueId:
                                                  suggestion['league_id']);
                                          m = Message(
                                              sender: provider
                                                  .turns[provider.turn]['name'],
                                              uid: provider.turns[provider.turn]
                                                  ['uid'],
                                              image:
                                                  provider.turns[provider.turn]
                                                      ['image'],
                                              correct: true,
                                              text:
                                                  'Find a player that played for ${suggestion['name']}',
                                              arabicText:
                                                  "ابحث عن لاعب لعب لـ ${suggestion['name']}",
                                              reason:
                                                  "${provider.currentPlayer!.name} did play for ${suggestion['name']}",
                                              arabicReason:
                                                  "${provider.currentPlayer!.name} لعب لـ ${suggestion['name']}",
                                              club: provider.currentClub);
                                        }
                                      } else {
                                        m = Message(
                                            correct: false,
                                            sender: provider
                                                .turns[provider.turn]['name'],
                                            uid: provider.turns[provider.turn]
                                                ['uid'],
                                            image: provider.turns[provider.turn]
                                                ['image'],
                                            text:
                                                'Find a player that played for ${suggestion['name']}',
                                            arabicText:
                                                "ابحث عن لاعب لعب لـ ${suggestion['name']}",
                                            reason:
                                                '${provider.currentPlayer!.name} did not play for ${suggestion['name']}',
                                            arabicReason:
                                                '${provider.currentPlayer!.name} لم يلعب لـ ${suggestion['name']}',
                                            club: Club(
                                                id: suggestion['id'],
                                                name: suggestion['name'],
                                                logo: suggestion['logo'],
                                                leagueId:
                                                    suggestion['league_id']));
                                      }
                                      provider.currentClub = Club(
                                          id: suggestion['id'],
                                          name: suggestion['name'],
                                          logo: suggestion['logo'],
                                          leagueId: suggestion['league_id']);
                                      provider.isClub = false;

                                      provider.selectClub(widget.playerTime, m);

                                      progress.dismiss();
                                    },
                                  )
                                : SizedBox())
                            : (myUser!.uid ==
                                    provider.turns[roomData['turn']]['uid']
                                ? PlayersSearchWidget(
                                    leagueId: widget.leagueIds,
                                    callback: (suggestion) async {
                                      final progress = ProgressHUD.of(context);
                                      progress!.show();
                                      if (provider.usedPlayers
                                          .contains(suggestion['id'])) {
                                        showSnackBar(
                                            AppLocalizations.of(context)!
                                                .thisPlayerHaveBeenUsedBefore);
                                        progress.dismiss();

                                        return;
                                      } else {
                                        late Message m;

                                        if (await _dbHelper
                                            .validatePlayerInClub(
                                                suggestion['id'],
                                                provider.currentClub!.id)) {
                                          m = Message(
                                              correct: true,
                                              sender: provider
                                                  .turns[provider.turn]['name'],
                                              uid: provider.turns[provider.turn]
                                                  ['uid'],
                                              image:
                                                  provider.turns[provider.turn]
                                                      ['image'],
                                              text:
                                                  "Find a club that ${suggestion['name']} played for",
                                              arabicText:
                                                  "ابحث عن نادٍ ${suggestion['name']} لعب لـه",
                                              reason:
                                                  "${suggestion['name']} did play for ${provider.currentClub!.name}",
                                              arabicReason:
                                                  "${suggestion['name']} لعب لـ ${provider.currentClub!.name}",
                                              player: Player(
                                                  id: suggestion['id'],
                                                  name: suggestion['name'],
                                                  fullName:
                                                      suggestion['full_name'],
                                                  nameInHomeCountry: suggestion[
                                                      'name_in_home_country'],
                                                  image: suggestion['image']));
                                        } else {
                                          m = Message(
                                              correct: false,
                                              sender: provider
                                                  .turns[provider.turn]['name'],
                                              uid: provider.turns[provider.turn]
                                                  ['uid'],
                                              image:
                                                  provider.turns[provider.turn]
                                                      ['image'],
                                              text:
                                                  "Finad a club that ${suggestion['name']} played for",
                                              arabicText:
                                                  "ابحث عن نادٍ ${suggestion['name']} لعب لـه",
                                              reason:
                                                  "${suggestion['name']} did not play for ${provider.currentClub!.name}",
                                              arabicReason:
                                                  "${suggestion['name']} لم يلعب لـ ${provider.currentClub!.name}",
                                              player: Player(
                                                  id: suggestion['id'],
                                                  name: suggestion['name'],
                                                  fullName:
                                                      suggestion['full_name'],
                                                  nameInHomeCountry: suggestion[
                                                      'name_in_home_country'],
                                                  image: suggestion['image']));
                                        }
                                        provider.currentPlayer = Player(
                                            id: suggestion['id'],
                                            name: suggestion['name'],
                                            fullName: suggestion['full_name'],
                                            nameInHomeCountry: suggestion[
                                                'name_in_home_country'],
                                            image: suggestion['image']);
                                        provider.isClub = true;
                                        provider.usedPlayers.add(
                                          suggestion['id'],
                                        );
                                        await provider.selectPlayer(
                                            widget.playerTime, m);
                                      }
                                      progress.dismiss();
                                    },
                                  )
                                : SizedBox()),
                      );
                    }
                    return const Center(
                      child: Text("Error"),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
