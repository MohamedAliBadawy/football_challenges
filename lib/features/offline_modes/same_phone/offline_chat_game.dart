import 'package:flutter/material.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:football_challenges/core/audio/audio_controller.dart';
import 'package:football_challenges/core/audio/sounds.dart';
import 'package:football_challenges/core/db_helper.dart';
import 'package:football_challenges/core/style/snack_bar.dart';
import 'package:football_challenges/features/offline_modes/same_phone/offline_game_appbar_provider.dart';
import 'package:football_challenges/features/offline_modes/same_phone/user_player_model.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/message_model.dart';
import 'package:football_challenges/models/player_model.dart';
import 'package:football_challenges/widgets/clubs_search.dart';
import 'package:football_challenges/widgets/left_message_widget.dart';
import 'package:football_challenges/widgets/players_search.dart';
import 'package:football_challenges/widgets/right_message_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final int initialClub;
  final List<int> leagueIds;
  final List<UserPlayer> teamA;
  final List<UserPlayer> teamB;
  final int playerTime;
  final int winScore;

  const ChatScreen({
    super.key,
    required this.initialClub,
    required this.leagueIds,
    required this.teamA,
    required this.teamB,
    required this.playerTime,
    required this.winScore,
  });
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int teamAScore = 0;
  int teamBScore = 0;
  Club? _currentClub;
  Player? _currentPlayer;
  Set<int> _usedPlayers = {};
  bool isClub = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late OfflineGameAppbarProvider provider;

  @override
  void initState() {
    sendInitialMessage(widget.initialClub);
    provider = OfflineGameAppbarProvider()
      ..initialize(widget.initialClub, widget.teamA, widget.teamB,
          widget.playerTime, widget.winScore, context);
    super.initState();
  }

  void sendInitialMessage(int initialClub) async {
    _currentClub = await _dbHelper.getClubsById(initialClub);
    provider.messages.add(Message(
        correct: true,
        sender: AppLocalizations.of(context)!.gameMaster,
        text:
            '${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${_currentClub!.name}',
        club: _currentClub,
        uid: "xxx",
        first: true));
  }

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AudioController>();

    return ChangeNotifierProvider.value(
      value: provider,
      child: ProgressHUD(
        child: Builder(builder: (context2) {
          provider.context = context2;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Consumer<OfflineGameAppbarProvider>(
                builder: (context, provider, child) {
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
                              child: Text(
                                "${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.turn}",
                                style: const TextStyle(
                                  fontFamily: 'Permanent Marker',
                                ),
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
                            "${provider.teamAScore}",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          ),
                          Flexible(
                              flex: 2,
                              child: Text(
                                "${AppLocalizations.of(context)!.remainingTime}: ${provider.remainingTime}",
                                style: const TextStyle(
                                  fontFamily: 'Permanent Marker',
                                ),
                              )),
                          Text(
                            "${provider.teamBScore}",
                            style: const TextStyle(
                              fontFamily: 'Permanent Marker',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Consumer<OfflineGameAppbarProvider>(
                        builder: (context, provider, child) {
                      return ListView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        itemCount: provider.messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              provider.messages.reversed.toList()[index];

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: message.sender ==
                                    provider.turns[0].name.trim()
                                ? rightMessageWidget(context, message, () {
                                    final progress = ProgressHUD.of(context2);
                                    progress!.show();
                                    audioController
                                        .playSfx(SfxType.refereeWhistleBlow);
                                    setState(() {
                                      message.cheating = true;
                                      int prev = provider.lastTurn();

                                      if (message.correct == true) {
                                        final progress =
                                            ProgressHUD.of(context2);
                                        progress!.show();
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            uid: "xxx",
                                            first: true,
                                            text:
                                                "${provider.turns[prev].name} ${AppLocalizations.of(context)!.isNotCheating}\n${message.reason}\n${provider.turns[prev].name} ${AppLocalizations.of(context)!.scoredAPointForTeam} ${provider.turns[prev].team}"));
                                        if (provider.turns[prev].team == 'A')
                                          provider.teamAScored();
                                        else if (provider.turns[prev].team ==
                                            'B') provider.teamBScored();
                                      } else {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            first: true,
                                            uid: "xxx",
                                            text:
                                                "${provider.turns[prev].name} ${AppLocalizations.of(context)!.isCheating}\n${message.reason}\n${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.scoredAPointForTeam} ${provider.turns[provider.turn].team}"));
                                        if (provider
                                                .turns[provider.turn].team ==
                                            'A')
                                          provider.teamAScored();
                                        else if (provider
                                                .turns[provider.turn].team ==
                                            'B') provider.teamBScored();
                                      }
                                      provider.evaluate();
                                      provider.nextTurn(widget.playerTime);
                                      if (!isClub) {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            first: true,
                                            uid: "xxx",
                                            text:
                                                "${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${_currentClub!.name}"));
                                      } else if (isClub) {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            uid: "xxx",
                                            first: true,
                                            text:
                                                "${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAClubThat} ${_currentPlayer!.name} ${AppLocalizations.of(context)!.playedFor}"));
                                      }
                                      progress.dismiss();
                                    });
                                  })
                                : leftMessageWidget(context, message, () {
                                    final progress = ProgressHUD.of(context2);
                                    progress!.show();
                                    audioController
                                        .playSfx(SfxType.refereeWhistleBlow);
                                    setState(() {
                                      message.cheating = true;
                                      int prev = provider.lastTurn();

                                      if (message.correct == true) {
                                        final progress =
                                            ProgressHUD.of(context2);
                                        progress!.show();
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            uid: "xxx",
                                            first: true,
                                            text:
                                                "${provider.turns[prev].name} ${AppLocalizations.of(context)!.isNotCheating}\n${message.reason}\n${provider.turns[prev].name} ${AppLocalizations.of(context)!.scoredAPointForTeam} ${provider.turns[prev].team}"));
                                        if (provider.turns[prev].team == 'A')
                                          provider.teamAScored();
                                        else if (provider.turns[prev].team ==
                                            'B') provider.teamBScored();
                                      } else {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            first: true,
                                            uid: "xxx",
                                            text:
                                                "${provider.turns[prev].name} ${AppLocalizations.of(context)!.isCheating}\n${message.reason}\n${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.scoredAPointForTeam} ${provider.turns[provider.turn].team}"));
                                        if (provider
                                                .turns[provider.turn].team ==
                                            'A')
                                          provider.teamAScored();
                                        else if (provider
                                                .turns[provider.turn].team ==
                                            'B') provider.teamBScored();
                                      }

                                      provider.evaluate();
                                      provider.nextTurn(widget.playerTime);
                                      if (!isClub) {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            first: true,
                                            uid: "xxx",
                                            text:
                                                "${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${_currentClub!.name}"));
                                      } else if (isClub) {
                                        provider.messages.add(Message(
                                            sender:
                                                AppLocalizations.of(context)!
                                                    .gameMaster,
                                            uid: "xxx",
                                            first: true,
                                            text:
                                                "${provider.turns[provider.turn].name} ${AppLocalizations.of(context)!.turn}!\n${AppLocalizations.of(context)!.findAClubThat} ${_currentPlayer!.name} ${AppLocalizations.of(context)!.playedFor}"));
                                      }
                                      progress.dismiss();
                                    });
                                  }),
                          );
                        },
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isClub
                        ? ClubsSearchWidget(
                            leagueId: widget.leagueIds,
                            callback: (suggestion) async {
                              final progress = ProgressHUD.of(context2);
                              progress!.show();
                              if (await _dbHelper.validatePlayerInClub(
                                  _currentPlayer!.id, suggestion['id'])) {
                                if (_currentClub!.id == suggestion['id']) {
                                  final playerHistory =
                                      await _dbHelper.getAllPlayerClubs(
                                          _currentPlayer!.id, widget.leagueIds);
                                  if (playerHistory.length == 1 &&
                                      _currentClub!.id == suggestion['id']) {
                                    isClub = false;
                                    provider.messages.add(Message(
                                        correct: true,
                                        uid: "xxx",
                                        sender:
                                            provider.turns[provider.turn].name,
                                        text:
                                            '${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${suggestion['name']}',
                                        reason:
                                            "${_currentPlayer!.name} ${AppLocalizations.of(context)!.playedOnlyFor} ${suggestion['name']} ${AppLocalizations.of(context)!.inTheSelectedLeagues}",
                                        club: _currentClub));
                                  } else {
                                    provider.messages.add(Message(
                                        correct: false,
                                        uid: "xxx",
                                        sender:
                                            provider.turns[provider.turn].name,
                                        text:
                                            '${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${suggestion['name']}',
                                        reason:
                                            "${_currentPlayer!.name} ${AppLocalizations.of(context)!.playedForAnotherClubInTheSelectedLeagues}",
                                        club: _currentClub));
                                  }
                                } else {
                                  _currentClub = Club(
                                      id: suggestion['id'],
                                      name: suggestion['name'],
                                      logo: suggestion['logo'],
                                      leagueId: suggestion['league_id']);
                                  provider.messages.add(Message(
                                      sender:
                                          provider.turns[provider.turn].name,
                                      uid: "xxx",
                                      correct: true,
                                      text:
                                          '${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${suggestion['name']}',
                                      reason:
                                          '${_currentPlayer!.name} ${AppLocalizations.of(context)!.didPlayFor} ${suggestion['name']}',
                                      club: _currentClub));
                                }
                              } else {
                                provider.messages.add(Message(
                                    correct: false,
                                    uid: "xxx",
                                    sender: provider.turns[provider.turn].name,
                                    text:
                                        '${AppLocalizations.of(context)!.findAPlayerThatPlayedFor} ${suggestion['name']}',
                                    reason:
                                        '${_currentPlayer!.name} ${AppLocalizations.of(context)!.didNotPlayFor} ${suggestion['name']}',
                                    club: Club(
                                        id: suggestion['id'],
                                        name: suggestion['name'],
                                        logo: suggestion['logo'],
                                        leagueId: suggestion['league_id'])));
                              }
                              _currentClub = Club(
                                  id: suggestion['id'],
                                  name: suggestion['name'],
                                  logo: suggestion['logo'],
                                  leagueId: suggestion['league_id']);
                              isClub = false;

                              provider.messages[provider.messages.length - 2]
                                  .cheating = true;
                              provider.nextTurn(widget.playerTime);
                              progress.dismiss();

                              setState(() {});
                            },
                          )
                        : PlayersSearchWidget(
                            leagueId: widget.leagueIds,
                            callback: (suggestion) async {
                              final progress = ProgressHUD.of(context2);
                              progress!.show();
                              if (_usedPlayers.contains(suggestion['id'])) {
                                showSnackBar(AppLocalizations.of(context)!
                                    .thisPlayerHaveBeenUsedBefore);
                                progress.dismiss();

                                return;
                              }
                              if (await _dbHelper.validatePlayerInClub(
                                  suggestion['id'], _currentClub!.id)) {
                                provider.messages.add(Message(
                                    correct: true,
                                    uid: "xxx",
                                    sender: provider.turns[provider.turn].name,
                                    text:
                                        '${AppLocalizations.of(context)!.findAClubThat} ${suggestion['name']} ${AppLocalizations.of(context)!.playedFor}',
                                    reason:
                                        '${suggestion['name']} ${AppLocalizations.of(context)!.didPlayFor} ${_currentClub!.name}',
                                    player: Player(
                                        id: suggestion['id'],
                                        name: suggestion['name'],
                                        fullName: suggestion['full_name'],
                                        nameInHomeCountry:
                                            suggestion['name_in_home_country'],
                                        image: suggestion['image'])));
                              } else {
                                provider.messages.add(Message(
                                    correct: false,
                                    uid: "xxx",
                                    sender: provider.turns[provider.turn].name,
                                    text:
                                        '${AppLocalizations.of(context)!.findAClubThat} ${suggestion['name']} ${AppLocalizations.of(context)!.playedFor}',
                                    reason:
                                        '${suggestion['name']} ${AppLocalizations.of(context)!.didNotPlayFor} ${_currentClub!.name}',
                                    player: Player(
                                        id: suggestion['id'],
                                        name: suggestion['name'],
                                        fullName: suggestion['full_name'],
                                        nameInHomeCountry:
                                            suggestion['name_in_home_country'],
                                        image: suggestion['image'])));
                              }
                              _currentPlayer = Player(
                                  id: suggestion['id'],
                                  name: suggestion['name'],
                                  fullName: suggestion['full_name'],
                                  nameInHomeCountry:
                                      suggestion['name_in_home_country'],
                                  image: suggestion['image']);
                              isClub = true;
                              _usedPlayers.add(
                                suggestion['id'],
                              );
                              provider.messages[provider.messages.length - 2]
                                  .cheating = true;

                              provider.nextTurn(widget.playerTime);
                              progress.dismiss();

                              setState(() {});
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
